# frozen_string_literal: true

require 'typhoeus/response/header'
require 'typhoeus/response/informations'
require 'typhoeus/response/status'
require 'typhoeus/response/cacheable'

module Typhoeus

  # This class represents the response.
  class Response
    include Response::Informations
    include Response::Status
    include Response::Cacheable

    # Remembers the corresponding request.
    #
    # @example Get request.
    #   request = Typhoeus::Request.new("www.example.com")
    #   response = request.run
    #   request == response.request
    #   #=> true
    #
    # @return [ Typhoeus::Request ]
    attr_accessor :request

    # The provided options, which contain all the
    # informations about the request.
    #
    # @return [ Hash ]
    attr_accessor :options

    # Set the handled response.
    attr_writer :handled_response

    # @api private
    attr_writer :mock

    # Create a new response.
    #
    # @example Create a response.
    #  Response.new
    #
    # @param [ Hash ] options The options hash.
    #
    # @return [ Response ] The new response.
    def initialize(options = {})
      @options = options
      @headers = Header.new(options[:headers]) if options[:headers]
    end

    # Keep duplicated responses independent. Memoization hands a copy of the
    # leader's response to every follower, so shared options, headers, bodies,
    # or callback results would let one request change another one's response.
    def initialize_copy(other)
      super
      @options = duplicate_value(other.options)
      @handled_response = nil
      if other.instance_variable_defined?(:@headers)
        headers = other.instance_variable_get(:@headers)
        @headers = headers.dup if headers
      end
    end
    private :initialize_copy

    # Returns whether this request is mocked
    # or not.
    #
    # @api private
    def mock
      defined?(@mock) ? @mock : options[:mock]
    end
    alias :mock? :mock

    # Returns the handled_response if it has
    # been defined; otherwise, returns the response
    #
    # @return [ Object ] The result of callbacks
    #   done on the response or the original response.
    def handled_response
      @handled_response || self
    end

    private

    # Duplicate the mutable containers a response may share with its copy.
    # Other option values are opaque and are left alone.
    def duplicate_value(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested), copy|
          copy[duplicate_value(key)] = duplicate_value(nested)
        end
      when Array
        value.map { |nested| duplicate_value(nested) }
      when String
        value.dup
      else
        value
      end
    end
  end
end
