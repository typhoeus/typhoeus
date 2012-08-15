module Typhoeus

  # This class represents an expectation. It is part
  # of the stubbing mechanism. An expectation contains
  # an url and options, like a request. They were compared
  # to the request url and options in order to evaluate
  # wether they match. If thats the case, the attached
  # responses were returned one by one.
  class Expectation
    attr_reader :url, :options

    class << self

      # Returns all expectations.
      #
      # @example Return expectations.
      #   Typhoeus::Expectation.all
      #
      # @return [ Array ] The expectations.
      def all
        @expectations ||= []
      end

      # Clears expectations.
      #
      # @example Clear expectations.
      #   Typhoeus:;Expectation.clear
      def clear
        all.clear
      end

      # Returns expecation matching the provided
      # request.
      #
      # @example Find expectation.
      #   Typhoeus::Expectation.find_by(request)
      #
      # @return [ Expectation ] The matching expectation.
      def find_by(request)
        all.find do |expectation|
          expectation.matches?(request)
        end
      end
    end

    # Creates an expactation.
    #
    # @example Create expactation.
    #   Typhoeus::Expectation.new(url)
    #
    # @return [ Expectation ] The created expactation.
    def initialize(url, options = {})
      @url = url
      @options = options
      @response_counter = 0
    end

    # Specify what should be returned,
    # when this expactation is hit.
    #
    # @example Add response.
    #   expectation.and_return(response)
    def and_return(response)
      responses << response
    end

    # Checks wether this expectation matches
    # the provided request.
    #
    # @example Check if request matches.
    #   expectation.matches? request
    #
    # @param [ Request ] The request to check.
    #
    # @return [ Boolean ] True when matches, else false.
    def matches?(request)
      url_match?(request.url) &&
        (options ? options.all?{ |k,v| request.original_options[k] == v } : true)
    end

    # Return canned responses.
    #
    # @example Return responses.
    #   expectation.responses
    #
    # @return [ Array ] The responses.
    def responses
      @responses ||= []
    end

    # Return the response. When there are
    # multiple responses, they were returned one
    # by one.
    #
    # @example Return response.
    #   expectation.response
    #
    # @return [ Response ] The response.
    def response
      response = responses.fetch(@response_counter, responses.last)
      @response_counter += 1
      response
    end

    private

    # Check wether the url matches the request url.
    # The url can be a string, regex or nil. String and
    # regexp were checked, nil is always true. Else false.
    #
    # Nil serves as a placeholder in case you want to match
    # all urls.
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
