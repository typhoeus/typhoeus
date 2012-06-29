require 'typhoeus/responses/legacy'
require 'typhoeus/responses/informations'
require 'typhoeus/responses/status'
require 'typhoeus/responses/header'

module Typhoeus

  # This class respresents the response.
  class Response
    include Responses::Status
    include Responses::Informations
    include Responses::Legacy

    attr_accessor :request, :options

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
    end
  end
end
