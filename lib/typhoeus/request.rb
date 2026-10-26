# frozen_string_literal: true

require 'zlib'
require 'digest/sha1'
require 'typhoeus/request/actions'
require 'typhoeus/request/before'
require 'typhoeus/request/block_connection'
require 'typhoeus/request/cacheable'
require 'typhoeus/request/callbacks'
require 'typhoeus/request/marshal'
require 'typhoeus/request/memoizable'
require 'typhoeus/request/operations'
require 'typhoeus/request/responseable'
require 'typhoeus/request/streamable'
require 'typhoeus/request/stubbable'

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
    extend  Request::Actions
    include Request::Callbacks::Types
    include Request::Callbacks
    include Request::Streamable
    include Request::Marshal
    include Request::Operations
    include Request::Responseable
    include Request::Memoizable
    include Request::Cacheable
    include Request::BlockConnection
    include Request::Stubbable
    include Request::Before

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

        # Let Ethon apply its escape rule for this method and version. Ethon
        # 0.18 always escapes PUT bodies; 0.19 respects the escape option like
        # POST does. The form must stay non-multipart: encoded_body returns a
        # single string, and Ethon 0.18 mistakes plain array values for files
        # when it builds a multipart form.
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
      expect_key = headers.keys.find { |key| key.to_s.casecmp?("Expect") }
      if expect_key
        headers[expect_key] ||= ""
      else
        headers["Expect"] = ""
      end
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
