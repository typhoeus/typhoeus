# frozen_string_literal: true

module Typhoeus
  class Hydra

    # This module handles the GET request memoization
    # on the hydra side. Memoization needs to be
    # turned on:
    #   Typhoeus.configure do |config|
    #     config.memoize = true
    #   end
    #
    # @api private
    module Memoizable

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

      # Add a request. Memoized requests that are already completed are
      # answered from memory. Requests that are still in flight are attached
      # to the pending request so they share its response.
      #
      # @param [ Typhoeus::Request ] request
      #
      # @return [ Object ]
      def add(request)
        if request.memoizable?
          if memory.key?(request)
            finish_request(request, memory[request])
            dequeue_many
          elsif pending.key?(request)
            pending[request] << request
          else
            pending[request] = []
            request.on_complete { |response| finish_pending(request, response) }
            begin
              super
            rescue Exception
              pending.delete(request)
              raise
            end
          end
        else
          super
        end
      end

      # Run the hydra and memoize requests for the duration of the run.
      #
      # @example Run hydra.
      #   hydra.run
      def run
        memory.clear
        super
      ensure
        finish_pending_after_error
        memory.clear
        pending.clear
      end

      private

      # Finish all requests that waited for the given request.
      #
      # @param [ Typhoeus::Request ] request
      # @param [ Typhoeus::Response ] response
      #
      # @return [ Object ] The response's handled response.
      def finish_pending(request, response)
        requests = pending.delete(request)
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
        pending.each do |request, requests|
          response = memory[request]
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
    end
  end
end
