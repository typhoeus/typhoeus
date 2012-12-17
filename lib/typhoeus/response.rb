require 'typhoeus/response/header'
require 'typhoeus/response/informations'
require 'typhoeus/response/status'

module Typhoeus

  # This class respresents the response.
  class Response
    include Response::Informations
    include Response::Status

    # Remembers the corresponding request.
    #
    # @example Get request.
    #   request = Typhoeus::Request.get("www.example.com")
    #   response = request.run
    #   request == response.request
    #   #=> true
    #
    # @return [ Typhoeus::Request ]
    attr_accessor :request

    # The options provided, contains all the
    # informations about the request.
    #
    # @return [ Hash ]
    attr_accessor :options

    # The handled response.
    #
    # @return [ String ]
    attr_accessor :handled_response

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

    # Returns wether this request is mocked
    # or not.
    #
    # @api private
    def mock
      defined?(@mock) ? @mock : options[:mock]
    end
  end
end
