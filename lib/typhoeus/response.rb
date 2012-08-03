require 'typhoeus/responses/header'
require 'typhoeus/responses/informations'
require 'typhoeus/responses/legacy'
require 'typhoeus/responses/status'

module Typhoeus

  # This class respresents the response.
  class Response
    include Responses::Informations
    include Responses::Legacy
    include Responses::Status

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
