module Typhoeus
  class Expectation
    attr_reader :url, :options

    class << self
      def all
        @expectations ||= []
      end

      def clear
        all.clear
      end

      def find_by(request)
        all.find do |expectation|
          expectation.matches?(request)
        end
      end
    end

    def initialize(url, options = {})
      @url = url
      @options = options
      @response_counter = 0
    end

    def and_return(response)
      responses << response
    end

    def matches?(request)
      url_match?(request.url) &&
        (options ? options.all?{ |k,v| request.original_options[k] == v } : true)
    end

    def responses
      @responses ||= []
    end

    def response
      response = responses.fetch(@response_counter, responses.last)
      @response_counter += 1
      response
    end

    private

    def url_match?(request_url)
      case url
      when String
        url == request_url
      when Regexp
        !!request_url.match(url)
      when nil
        true
      else
        false
      end
    end
  end
end
