require 'typhoeus/response/header'
require 'typhoeus/response/informations'
require 'typhoeus/response/legacy'
require 'typhoeus/response/status'

module Typhoeus

  # This class respresents the response.
  class Response
    include Response::Informations
    include Response::Legacy
    include Response::Status

    attr_accessor :request, :options, :mock

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
      @headers = options[:headers]
    end
  end
end
