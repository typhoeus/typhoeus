require 'typhoeus/requests/callbacks'
require 'typhoeus/requests/actions'
require 'typhoeus/requests/operations'
require 'typhoeus/requests/marshal'
require 'typhoeus/requests/responseable'
require 'typhoeus/requests/memoizable'

module Typhoeus

  # This class represents a request.
  class Request
    include Requests::Callbacks
    include Requests::Marshal
    include Requests::Operations
    extend  Requests::Actions
    include Requests::Responseable
    include Requests::Memoizable

    attr_accessor :options, :url, :hydra

    # Create a new request.
    #
    # @example Create a request.
    #   Request.new("www.example.com")
    #
    # @param [ String ] url The url to request.
    # @param [ Hash ] options The options.
    #
    # #return [ Request ] The new request.
    def initialize(url, options = {})
      @url = url
      @options = options.dup

      if @options[:headers]
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(options[:headers])
      else
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end
      @options[:verbose] = Typhoeus::Config.verbose if @options[:verbose].nil?
    end

    # Returns wether other is equal to self.
    #
    # @example Are request equal?
    #   request.eql?(other_request)
    #
    # @param [ Object ] other The object to check.
    #
    # @return [ Boolean ] Returns true if equals, else false.
    def eql?(other)
      self.class == other.class &&
        self.url == other.url &&
        self.options == other.options
    end

    # Overrides Object#hash.
    #
    # @return [ Integer ] The integer representing the request.
    def hash
      [ self.class, self.url, self.options ].hash
    end
  end
end
