module Typhoeus
  class Expectation
    attr_reader :url, :options

    class << self
      def find_by(request)
        Typhoeus.expectations.find do |expectation|
          expectation.matches?(request)
        end
      end
    end

    def initialize(url, options = {})
      @url = url
      @options = options
    end

    def and_return(response)
      responses << response
    end

    def matches?(request)
      (url ? url == request.url : true) &&
        (options ? options.all?{ |k,v| request.original_options[k] == v } : true)
    end

    def responses
      @responses ||= []
    end

    def response
      responses.last
    end
  end
end
