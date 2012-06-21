require 'typhoeus/responses/legacy'
require 'typhoeus/responses/informations'
require 'typhoeus/responses/mock'
require 'typhoeus/responses/status'

module Typhoeus
  class Response
    include Responses::Status
    include Responses::Informations
    include Responses::Legacy
    include Responses::Mock

    attr_accessor :request, :options

    def initialize(options = {})
      @options = options
    end
  end
end
