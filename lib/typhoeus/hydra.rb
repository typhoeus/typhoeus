# frozen_string_literal: true

require 'typhoeus/hydra/queueable'

module Typhoeus

  # Hydra manages making parallel HTTP requests. This
  # is achieved by using libcurls multi interface:
  # http://curl.haxx.se/libcurl/c/libcurl-multi.html
  # The benefits are that you don't have to worry running
  # the requests by yourself.
  #
  # Hydra will also handle how many requests you can
  # make in parallel. Things will get flakey if you
  # try to make too many requests at the same time.
  # The built in limit is 200. When more requests than
  # that are queued up, hydra will save them for later
  # and start the requests as others are finished. You
  # can raise or lower the concurrency limit through
  # the Hydra constructor.
  #
  # Regarding the asynchronous behavior of the hydra,
  # it is important to know that this is completely hidden
  # from the developer and you are free to apply
  # whatever technique you want to your code. That should not
  # conflict with libcurls internal concurrency mechanism.
  #
  # @example Use the hydra to do multiple requests.
  #   hydra = Typhoeus::Hydra.new
  #   requests = (0..9).map{ Typhoeus::Request.new("www.example.com") }
  #   requests.each{ |request| hydra.queue(request) }
  #   hydra.run
  #
  # @note Callbacks are going to delay the request
  #   execution.
  class Hydra
    include Hydra::Queueable

    # @example Set max_concurrency.
    #   Typhoeus::Hydra.new(max_concurrency: 20)
    #
    # @return [ Integer ] The maximum number of concurrent requests.
    attr_reader :max_concurrency

    class << self

      # Returns a memoized hydra instance.
      #
      # @example Get a hydra.
      #   Typhoeus::Hydra.hydra
      #
      # @return [Typhoeus::Hydra] A new hydra.
      def hydra
        Thread.current[:typhoeus_hydra] ||= new
      end
    end

    # Create a new hydra. All
    # {http://rubydoc.info/github/typhoeus/ethon/Ethon/Multi#initialize-instance_method Ethon::Multi#initialize}
    # options are also available.
    #
    # @example Create a hydra.
    #   Typhoeus::Hydra.new
    #
    # @example Create a hydra with max_concurrency.
    #   Typhoeus::Hydra.new(max_concurrency: 20)
    #
    # @param [ Hash ] options The options hash.
    #
    # @option options :max_concurrency [ Integer ] Number
    #  of max concurrent connections to create. Default is
    #  200.
    #
    # @see http://rubydoc.info/github/typhoeus/ethon/Ethon/Multi#initialize-instance_method
    #   Ethon::Multi#initialize
    def initialize(options = {})
      @options = options.dup
      self.max_concurrency = @options.fetch(:max_concurrency, 200)
    end

    # Return the Ethon multi, creating it on first use. Constructing a Multi
    # initializes libcurl, which Ethon 0.19 refuses to do in a process that
    # forked after the parent initialized it. Creating or memoizing a Hydra
    # during boot must therefore not create the native handle yet.
    #
    # @return [ Ethon::Multi ] The multi handle.
    #
    # @api private
    def multi
      @multi ||= build_multi
    end

    # Add a request to the hydra.
    #
    # This is the hot path for every request. The checks are unrolled instead
    # of spread over a chain of included modules so a request that uses no
    # optional features takes the shortest route to the multi.
    #
    # @example Add request.
    #   hydra.add(request)
    #
    # @param [ Typhoeus::Request ] request The request to add.
    #
    # @return [ Object ] The result of the handling callback or the multi add.
    def add(request)
      request.hydra = self

      before_callbacks = Typhoeus.before_callbacks_for(request)
      if before_callbacks
        before_callbacks.each do |callback|
          value = callback.call(request)
          if value.is_a?(Response)
            unless request.response
              request.execute_headers_callbacks(value)
              request.on_body.each { |body_callback| body_callback.call(value.body, value) }
              request.finish(value)
            end
            dequeue_many
            return value
          elsif value.nil? || value == false
            dequeue_many
            return value
          end
        end
      end

      unless Typhoeus.stubs_disabled?
        if response = Expectation.response_for(request)
          # The stub block already ran the request for real.
          return if response.request

          request.execute_headers_callbacks(response)
          request.on_body.each { |callback| callback.call(response.body, response) }
          return request.finish(response)
        end
      end

      raise Typhoeus::Errors::NoStub.new(request) if request.blocked?

      if request.cacheable? && response = request.cached_response
        request.finish_cached_response(response)
        return dequeue_many
      end

      if request.memoizable?
        add_memoized(request)
      else
        add_to_multi(request)
      end
    end

    # Return the memory.
    #
    # @example Get memory.
    #   hydra.memory
    #
    # @return [ Hash ] The memory.
    def memory
      @memory ||= {}
    end

    # Requests that are waiting for an identical request to finish.
    #
    # @return [ Hash ]
    #
    # @api private
    def pending
      @pending ||= {}
    end

    # Start the hydra run.
    #
    # @example Start hydra run.
    #   hydra.run
    #
    # @return [ Symbol ] Return value from multi.perform.
    def run
      memory.clear
      dequeue_many
      # Nothing reached the multi (all requests were answered by a before
      # callback, a stub, or the cache), so do not initialize libcurl.
      return if !defined?(@multi) || @multi.nil?

      multi.perform
    rescue Exception => error
      begin
        cleanup_after_error
        reset_multi if multi_handle_unusable?(error)
      rescue StandardError
        # Preserve the original error.
      end
      raise
    ensure
      finish_pending_after_error
      memory.clear
      pending.clear
    end

    # Set the maximum number of concurrent requests.
    #
    # @example Set max_concurrency.
    #   hydra.max_concurrency = 20
    #
    # @param [ Integer, String ] value The maximum number of requests to run
    #   at the same time.
    #
    # @raise [ ArgumentError ] When the value is not greater than zero.
    #
    # @return [ Integer ] The maximum number of concurrent requests.
    def max_concurrency=(value)
      concurrency = Integer(value)
      if concurrency <= 0
        raise ArgumentError, "max_concurrency must be greater than zero"
      end
      @max_concurrency = concurrency
    end

    private

    # Add the easy handle for a request to the multi.
    #
    # @param [ Typhoeus::Request ] request The request to add.
    #
    # @return [ Object ] The result of the multi add.
    def add_to_multi(request)
      easy_factory = EasyFactory.new(request, self)
      easy = easy_factory.get
      begin
        multi.add(easy)
      rescue Exception
        easy_factory.release_easy(easy) unless easy_factory.released?
        raise
      end
    end

    # Answer a memoized request from memory or attach it to the request that
    # is already in flight.
    #
    # @param [ Typhoeus::Request ] request The request to add.
    #
    # @return [ Object ]
    def add_memoized(request)
      if memory.key?(request)
        finish_request(request, memory[request])
        dequeue_many
      elsif pending.key?(request)
        pending[request] << request
      else
        pending[request] = []
        request.on_complete do |response|
          # Finish from the snapshot taken before the leader's callbacks
          # ran. A callback that changes the leader's response must not
          # change the copy its followers receive. Keep the leader's own
          # callback result as this callback's return value.
          snapshot = memoized_response_for(request) || response
          finish_pending(request, snapshot)
          response.handled_response
        end
        begin
          add_to_multi(request)
        rescue Exception
          pending.delete(request)
          raise
        end
      end
    end

    # Finish all requests that waited for the given request.
    #
    # @param [ Typhoeus::Request ] request
    # @param [ Typhoeus::Response ] response
    #
    # @return [ Object ] The response's handled response.
    def finish_pending(request, response)
      requests = delete_pending(request)
      return response.handled_response unless requests

      error = nil
      requests.each do |pending_request|
        begin
          finish_request(pending_request, response)
        rescue StandardError => e
          error ||= e
        end
      end
      raise error if error

      response.handled_response
    end

    # Finish a request whose response is already available. Every request gets
    # its own response object and the same header callbacks it would see for
    # a stub or a cache hit.
    #
    # @param [ Typhoeus::Request ] request The waiting request.
    # @param [ Typhoeus::Response ] response The response to copy.
    #
    # @return [ Object ] The response's handled response.
    def finish_request(request, response)
      copy = response.dup
      copy.request = request
      request.execute_headers_callbacks(copy)
      request.finish(copy, true)
    end

    # Finish followers whose leader produced a response but whose callbacks
    # raised before finish_pending could run.
    #
    # @return [ void ]
    def finish_pending_after_error
      pending.to_a.each do |request, requests|
        response = memoized_response_for(request)
        next unless response

        requests.each do |pending_request|
          next if pending_request.response

          begin
            finish_request(pending_request, response)
          rescue StandardError
            # Preserve the original run error.
          end
        end
      end
    end

    # Remove the waiting requests without hashing the leader again.
    # Request#hash includes the request options, which a callback may have
    # changed after the entry was added.
    #
    # @param [ Typhoeus::Request ] request The leader request.
    #
    # @return [ Array<Typhoeus::Request>, nil ] The waiting requests.
    def delete_pending(request)
      requests = nil
      pending.delete_if do |pending_request, waiting_requests|
        next false unless pending_request.equal?(request)

        requests = waiting_requests
        true
      end
      requests
    end

    # Find the leader's response by identity for the same reason. A changed
    # option makes the request unusable as a hash key.
    #
    # @param [ Typhoeus::Request ] request The leader request.
    #
    # @return [ Typhoeus::Response, nil ] The memoized response.
    def memoized_response_for(request)
      memory.each_pair do |memoized_request, response|
        return response if memoized_request.equal?(request)
      end
      nil
    end

    # Clean up the easies and requests a failed run left behind.
    #
    # @return [ void ]
    def cleanup_after_error
      multi.easy_handles.dup.each do |easy|
        begin
          multi.delete(easy)
        rescue StandardError
          # The handle may already be unusable.
        end
        begin
          Typhoeus::Pool.release(easy, :cleanup => true)
        rescue StandardError
          # Keep cleaning up the remaining handles.
        end
      end
    ensure
      # A hydra that cannot create its multi has not dequeued anything, so
      # clear the queue even when the handles cannot be inspected.
      queued_requests.clear
    end

    # A fatal multi_perform error leaves the native multi handle in an
    # unknown state. Replace it so the hydra can run requests again.
    #
    # @return [ void ]
    def reset_multi
      begin
        multi.cleanup if multi.respond_to?(:cleanup)
      rescue StandardError
        # Freeing the old handle is best effort; it is unusable anyway.
      end
      @multi = build_multi
    end

    # Ethon 0.19 raises MultiPerform when libcurl reports a fatal error from
    # curl_multi_perform. Earlier versions do not have the class.
    #
    # @param [ Exception ] error The error raised by the run.
    #
    # @return [ Boolean ] Whether the multi handle has to be replaced.
    def multi_handle_unusable?(error)
      defined?(Ethon::Errors::MultiPerform) &&
        error.is_a?(Ethon::Errors::MultiPerform)
    end

    # Build the multi handle from the options the hydra was created with.
    #
    # @return [ Ethon::Multi ] The new multi handle.
    #
    # @api private
    def build_multi
      Ethon::Multi.new(@options.reject { |key, _| key == :max_concurrency })
    end
  end
end
