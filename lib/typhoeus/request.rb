# frozen_string_literal: true

require 'zlib'
require 'digest/sha1'
require 'typhoeus/request/actions'
require 'typhoeus/request/callbacks'
require 'typhoeus/request/marshal'
require 'typhoeus/request/streamable'

module Typhoeus

  # This class represents a request.
  #
  # @example (see #initialize)
  #
  # @example Make a request with the shortcut.
  #   response = Typhoeus.get("www.example.com")
  #
  # @see (see #initialize)
  class Request
    extend Request::Actions
    include Request::Callbacks::Types
    include Request::Callbacks
    include Request::Streamable
    include Request::Marshal

    # Returns the provided base url.
    #
    # @return [ String ]
    attr_accessor :base_url

    # Returns options, which includes default parameters.
    #
    # @return [ Hash ]
    attr_accessor :options

    # Returns the hydra in which the request ran, if any.
    #
    # @return [ Typhoeus::Hydra ]
    #
    # @api private
    attr_accessor :hydra

    # Returns the original options provided.
    #
    # @return [ Hash ]
    #
    # @api private
    attr_accessor :original_options

    # @return [ Boolean ]
    #
    # @api private
    attr_accessor :block_connection

    # Creates a new request.
    #
    # @example Simplest request.
    #   response = Typhoeus::Request.new("www.example.com").run
    #
    # @example Request with url parameters.
    #   response = Typhoeus::Request.new(
    #     "www.example.com",
    #     params: {a: 1}
    #   ).run
    #
    # @example Request with a body.
    #   response = Typhoeus::Request.new(
    #     "www.example.com",
    #     body: {b: 2}
    #   ).run
    #
    # @example Request with parameters and body.
    #   response = Typhoeus::Request.new(
    #     "www.example.com",
    #     params: {a: 1},
    #     body: {b: 2}
    #   ).run
    #
    # @example Create a request and allow follow redirections.
    #   response = Typhoeus::Request.new(
    #     "www.example.com",
    #     followlocation: true
    #   ).run
    #
    # @param [ String ] base_url The url to request.
    # @param [ options ] options The options.
    #
    # @option options [ Hash ] :params Translated
    #   into url parameters.
    # @option options [ Hash ] :body Translated
    #   into HTTP POST request body.
    #
    # @return [ Typhoeus::Request ] The request.
    #
    # @note See {http://rubydoc.info/github/typhoeus/ethon/Ethon/Easy/Options Ethon::Easy::Options} for more options.
    #
    # @see Typhoeus::Hydra
    # @see Typhoeus::Response
    # @see Typhoeus::Request::Actions
    def initialize(base_url, options = {})
      @base_url = base_url
      @original_options = options
      @options = options.dup

      set_defaults
    end

    # Run the request.
    #
    # The before, stub, block connection, and cache checks run here explicitly
    # instead of relying on the order of included modules.
    #
    # @example Make a request.
    #   Typhoeus::Request.new("www.example.com").run
    #
    # @return [ Response ] The response.
    def run
      callbacks = Typhoeus.before_callbacks_for(self)
      if callbacks
        callbacks.each do |callback|
          value = callback.call(self)
          if value.is_a?(Response)
            unless response
              execute_headers_callbacks(value)
              on_body.each { |body_callback| body_callback.call(value.body, value) }
              finish(value)
            end
            return value
          end
          return response if value.nil? || value == false
        end
      end

      unless Typhoeus.stubs_disabled?
        if stub_response = Expectation.response_for(self)
          # The stub block already ran the request for real.
          return stub_response if stub_response.request

          execute_headers_callbacks(stub_response)
          on_body.each { |callback| callback.call(stub_response.body, stub_response) }
          return finish(stub_response)
        end
      end

      raise Typhoeus::Errors::NoStub.new(self) if blocked?

      if cached = cached_response
        return finish_cached_response(cached)
      end

      perform
    end

    # Add a callback that runs before the request.
    #
    # @example Add a callback.
    #   request.before { |request| request.options[:timeout] = 5 }
    #
    # @param [ Proc ] block The callback to run.
    #
    # @yield [ Typhoeus::Request ]
    #
    # @return [ Array<Proc> ] The callbacks.
    def before(&block)
      @before ||= []
      @before << block if block_given?
      @before
    end

    # Returns whether a request is blocked. Takes request.block_connection and
    # the connection state of the current thread into consideration.
    #
    # @example Blocked?
    #   request.blocked?
    #
    # @return [ Boolean ] True if blocked, false else.
    def blocked?
      if block_connection.nil?
        Typhoeus.connection_blocked?
      else
        block_connection
      end
    end

    # Return whether a request is memoizable.
    #
    # Streaming requests are not memoized because their body is not retained
    # and every caller has to receive its own chunks.
    #
    # @example Is request memoizable?
    #   request.memoizable?
    #
    # @return [ Boolean ] Return true if memoizable, false else.
    def memoizable?
      Typhoeus::Config.memoize &&
        !streaming? &&
        request_method == :get
    end

    # Return whether a request is cacheable.
    #
    # @return [ Boolean ]
    def cacheable?
      cache
    end

    # Return the cached response for the request, if there is one.
    #
    # @return [ Typhoeus::Response, nil ]
    #
    # @api private
    def cached_response
      cacheable? && cache.get(self)
    end

    # Finish a response that came from the cache and deliver it through the
    # same callbacks a stubbed response uses.
    #
    # @param [ Typhoeus::Response ] response The cached response.
    #
    # @return [ Typhoeus::Response ] The response.
    #
    # @api private
    def finish_cached_response(response)
      copy = response.dup
      copy.cached = true
      copy.request = self
      execute_headers_callbacks(copy)
      on_body.each { |callback| callback.call(copy.body, copy) }
      finish(copy)
    end

    # Return the cache TTL for the request.
    #
    # @return [ Integer, nil ]
    def cache_ttl
      options[:cache_ttl]
    end

    # Set the response and execute the callbacks.
    #
    # @param [ Typhoeus::Response ] response The response.
    # @param [ Boolean ] bypass_memoization Whether to bypass memoization.
    #
    # @return [ Typhoeus::Response ] The response.
    def finish(response, bypass_memoization = nil)
      if bypass_memoization
        @response = response
      else
        self.response = response
      end
      self.response.request = self
      execute_callbacks
      response
    end

    # Return the response.
    #
    # @return [ Typhoeus::Response, nil ]
    def response
      @response ||= nil
    end

    # Set the response. Cache and memoization hooks run explicitly before the
    # response is assigned, instead of relying on the order modules were
    # included in.
    #
    # @param [ Typhoeus::Response ] value The response to set.
    def response=(value)
      if cacheable? && cacheable_response?(value)
        # The request exposes this response to its callbacks and the caller.
        # Store a snapshot so later mutation cannot change what a cache hit
        # returns.
        cache.set(self, value.dup)
      end
      # Followers receive a copy of the stored response, and the leader's
      # callbacks must not change what they see. Store a snapshot instead of
      # the response the leader exposes to its own callbacks.
      hydra.memory[self] = value.dup if memoizable? && hydra
      @response = value
    end

    # Return the url.
    # In contrast to base_url which returns the value you specified, url returns
    # the full url including the parameters.
    #
    # @example Get the url.
    #   request.url
    #
    # @since 0.5.5
    def url
      EasyFactory.new(self).url
    end

    # Returns whether other is equal to self.
    #
    # @example Are request equal?
    #   request.eql?(other_request)
    #
    # @param [ Object ] other The object to check.
    #
    # @return [ Boolean ] Returns true if equal, else false.
    #
    # @api private
    def eql?(other)
      self.class == other.class &&
        base_url.to_s == other.base_url.to_s &&
        fuzzy_hash_eql?(normalized_options, other.normalized_options)
    end

    # Overrides Object#hash.
    #
    # @return [ Integer ] The integer representing the request.
    #
    # @api private
    def hash
      Zlib.crc32 cache_key
    end

    # Returns a cache key for use with caching methods that required a string
    # for a key. Will get used by ActiveSupport::Cache stores automatically.
    #
    # @return [ String ] The cache key.
    def cache_key
      # The cache store and the TTL only affect where and how long a response
      # is stored, not what the response is. Leaving them in the key would
      # silently miss the cache whenever the TTL changes.
      hashable_options = normalized_options.tap do |dup_opts|
        dup_opts.delete(:cache)
        dup_opts.delete(:cache_ttl)
      end

      cache_key_components = [
        self.class.name,
        base_url,
        hashable_string_for(hashable_options)
      ]

      Digest::SHA1.hexdigest(cache_key_components.join)
    end

    # Mimics libcurl's POST body generation. This is not accurate, but good
    # enough for VCR.
    #
    # @return [ String ] The encoded body.
    #
    # @api private
    def encoded_body
      easy = Typhoeus::Pool.get
      begin
        body_options = { :body => options[:body] }
        [:params_encoding, :escape].each do |option|
          body_options[option] = options[option] if options.key?(option)
        end

        # Let Ethon apply its escape rule for this method. The form must stay
        # non-multipart because encoded_body returns a single string.
        form = Ethon::Easy::Form.new(easy, options[:body])
        form.define_singleton_method(:multipart?) { false }

        action = if options.fetch(:method, :get).to_s.downcase == "put"
          Ethon::Easy::Http::Put.new("http://localhost/", body_options)
        else
          Ethon::Easy::Http::Post.new("http://localhost/", body_options)
        end
        action.instance_variable_set(:@form, form)
        action.setup(easy)
        form.to_s
      ensure
        Typhoeus::Pool.release(easy) if easy
      end
    end

    # Return the request method with the same defaults and spelling Ethon
    # uses. Cache keys, memoization, and equality must not depend on whether
    # the caller wrote :get, "GET", or omitted the default method.
    #
    # @return [ Symbol ] The normalized method.
    #
    # @api private
    def request_method
      (options[:method] || :get).to_s.downcase.to_sym
    end

    # Return the options with their implicit defaults filled in for comparison.
    #
    # @return [ Hash ] The normalized options.
    #
    # @api private
    def normalized_options
      normalized = options.merge(:method => request_method)
      normalized.delete("method")
      # GET is the default. Leaving it out keeps the cache key of an implicit
      # GET stable across the normalization change.
      normalized.delete(:method) if normalized[:method] == :get
      normalized
    end

    private

    # Perform the actual request.
    #
    # @return [ Typhoeus::Response ] The response.
    def perform
      easy_factory = EasyFactory.new(self)
      easy = easy_factory.get
      begin
        easy.perform
      rescue Exception
        easy_factory.release_easy(easy) unless easy_factory.released?
        raise
      end
      response
    end

    # Return the cache for the request, falling back to the global cache.
    #
    # @return [ Object, nil ]
    def cache
      return nil if options[:cache] === false
      options[:cache] || Typhoeus::Config.cache
    end

    # A streaming response has no buffered body, and a transport failure or a
    # stub is not a representation of the resource.
    #
    # @param [ Typhoeus::Response ] response The response to cache.
    #
    # @return [ Boolean ] Whether the response should be cached.
    def cacheable_response?(response)
      !response.cached? &&
        !streaming? &&
        !response.mock? &&
        (response.return_code.nil? || response.return_code == :ok)
    end

    # Checks if two hashes are equal or not, discarding
    # first-level hash order.
    #
    # @param [ Hash ] left
    # @param [ Hash ] right hash to check for equality
    #
    # @return [ Boolean ] Returns true if hashes have
    #   same values for same keys and same length,
    #   even if the keys are given in a different order.
    def fuzzy_hash_eql?(left, right)
      return true if (left == right)

      (left.count == right.count) && left.inject(true) do |res, kvp|
        res && (kvp[1] == right[kvp[0]])
      end
    end

    def hashable_string_for(obj)
      case obj
      when Hash
        pairs = obj.map do |key, value|
          "#{hashable_string_for(key)}#{hashable_string_for(value)}"
        end
        "hash:#{obj.size}:#{pairs.sort.join}"
      when Array
        values = obj.map { |value| hashable_string_for(value) }
        "array:#{obj.size}:#{values.join}"
      else
        value = obj.to_s
        "#{obj.class}:#{value.bytesize}:#{value}"
      end
    end

    # Sets default header and verbose when turned on.
    def set_defaults
      default_user_agent = Config.user_agent || Typhoeus::USER_AGENT

      headers = (options[:headers] || {}).dup
      unless header_key?(headers, "User-Agent")
        headers = {"User-Agent" => default_user_agent}.merge(headers)
      end
      # An empty value suppresses libcurl's 100-continue. A nil value opts out
      # of the header entirely, which lets libcurl add it when it sees fit.
      unless header_key?(headers, "Expect")
        headers["Expect"] = ""
      end
      headers.reject! { |key, value| key.to_s.casecmp?("Expect") && value.nil? }
      options[:headers] = headers
      options[:verbose] = Typhoeus::Config.verbose if options[:verbose].nil? && !Typhoeus::Config.verbose.nil?
      options[:timeout] = Typhoeus::Config.timeout if options[:timeout].nil? && !Typhoeus::Config.timeout.nil?
      options[:connecttimeout] = Typhoeus::Config.connecttimeout if options[:connecttimeout].nil? && !Typhoeus::Config.connecttimeout.nil?
      options[:maxredirs] ||= 50
      options[:proxy] = Typhoeus::Config.proxy unless options.has_key?(:proxy) || Typhoeus::Config.proxy.nil?
      options[:cainfo] = ENV["SSL_CERT_FILE"] if options[:cainfo].nil? && ENV["SSL_CERT_FILE"]
      options[:capath] = ENV["SSL_CERT_DIR"] if options[:capath].nil? && ENV["SSL_CERT_DIR"]
    end

    # Check the headers for a name without relying on its casing. Header names
    # are case-insensitive and libcurl sends every spelling it is given, so a
    # second default header would be added to the caller's value.
    #
    # @param [ Hash ] headers The request headers.
    # @param [ String ] name The header name to look for.
    #
    # @return [ Boolean ] Whether the header is already present.
    def header_key?(headers, name)
      headers.keys.any? { |key| key.to_s.casecmp?(name) }
    end
  end
end
