require 'typhoeus/request/actions'
require 'typhoeus/request/before'
require 'typhoeus/request/block_connection'
require 'typhoeus/request/callbacks'
require 'typhoeus/request/marshal'
require 'typhoeus/request/memoizable'
require 'typhoeus/request/operations'
require 'typhoeus/request/responseable'
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
    include Request::Marshal
    include Request::Operations
    include Request::Responseable
    include Request::Memoizable
    include Request::BlockConnection
    include Request::Stubbable
    include Request::Before

    # Set the url.
    #
    # @return [ String ]
    attr_writer :url

    # Returns the provided url.
    #
    # @return [ String ]
    def url
      @url.respond_to?(:call) ? @url.call : @url
    end

    # Returns options, which includes default parameters.
    #
    # @return [ Hash ]
    attr_accessor :options

    # Returns the hydra the request ran into if any.
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

    # Create a new request.
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
    # @example Evaluate a lazy url at request time.
    #   request = Typhoeus::Request.new(
    #     lambda { "http://example.com/?requested_at=#{Time.now.to_i}" }
    #   )
    #   # ...
    #   response = request.run
    #
    # @param [ String ] url The url to request.
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
    def initialize(url, options = {})
      @url = url
      @original_options = options
      @options = options.dup

      set_defaults
    end

    # Returns wether other is equal to self.
    #
    # @example Are request equal?
    #   request.eql?(other_request)
    #
    # @param [ Object ] other The object to check.
    #
    # @return [ Boolean ] Returns true if equals, else false.
    #
    # @api private
    def eql?(other)
      self.class == other.class &&
        self.url == other.url &&
        fuzzy_hash_eql?(self.options, other.options)
    end

    # Overrides Object#hash.
    #
    # @return [ Integer ] The integer representing the request.
    #
    # @api private
    def hash
      [ self.class, self.url, self.options ].hash
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

    # Sets default header and verbose when turned on.
    def set_defaults
      if @options[:headers]
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(options[:headers])
      else
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end
      @options[:verbose] = Typhoeus::Config.verbose if @options[:verbose].nil? && !Typhoeus::Config.verbose.nil?
    end
  end
end
