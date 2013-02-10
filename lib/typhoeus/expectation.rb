module Typhoeus

  # This class represents an expectation. It is part
  # of the stubbing mechanism. An expectation contains
  # an url and options, like a request. They were compared
  # to the request url and options in order to evaluate
  # wether they match. If thats the case, the attached
  # responses were returned one by one.
  #
  # @example Stub a request and get specified response.
  #   expected = Typhoeus::Response.new
  #   Typhoeus.stub("www.example.com").and_return(expected)
  #
  #   actual = Typhoeus.get("www.example.com")
  #   expected == actual
  #   #=> true
  class Expectation

    # @api private
    attr_reader :base_url

    # @api private
    attr_reader :options

    # @api private
    attr_reader :from

    class << self

      # Returns all expectations.
      #
      # @example Return expectations.
      #   Typhoeus::Expectation.all
      #
      # @return [ Array<Typhoeus::Expectation> ] The expectations.
      def all
        @expectations ||= []
      end

      # Clears expectations. This is handy while
      # testing and you want to make sure, that
      # you don't get canned responses.
      #
      # @example Clear expectations.
      #   Typhoeus::Expectation.clear
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
      #
      # @api private
      def find_by(request)
        all.find do |expectation|
          expectation.matches?(request)
        end
      end
    end

    # Creates an expectation.
    #
    # @example Create expectation.
    #   Typhoeus::Expectation.new(base_url)
    #
    # @return [ Expectation ] The created expectation.
    #
    # @api private
    def initialize(base_url, options = {})
      @base_url = base_url
      @options = options
      @response_counter = 0
      @from = nil
    end

    # Set from value to mark an expectaion. Useful for
    # other libraries, eg. webmock.
    #
    # @example Mark expectation.
    #   expectation.from(:webmock)
    #
    # @param [ String ] value Value to set.
    #
    # @return [ Expectation ] Returns self.
    #
    # @api private
    def stubbed_from(value)
      @from = value
      self
    end

    # Specify what should be returned,
    # when this expectation is hit.
    #
    # @example Add response.
    #   expectation.and_return(response)
    #
    # @return [ void ]
    def and_return(response)
      responses << response
    end

    # Checks wether this expectation matches
    # the provided request.
    #
    # @example Check if request matches.
    #   expectation.matches? request
    #
    # @param [ Request ] request The request to check.
    #
    # @return [ Boolean ] True when matches, else false.
    #
    # @api private
    def matches?(request)
      url_match?(request.base_url) && options_match?(request)
    end

    # Return canned responses.
    #
    # @example Return responses.
    #   expectation.responses
    #
    # @return [ Array<Typhoeus::Response> ] The responses.
    #
    # @api private
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
    #
    # @api private
    def response
      response = responses.fetch(@response_counter, responses.last)
      @response_counter += 1
      response.mock = @from || true
      response
    end

    private

    # Check wether the options matches the request options.
    # I checks options and original options.
    def options_match?(request)
      (options ? options.all?{ |k,v| request.original_options[k] == v || request.options[k] == v } : true)
    end

    # Check wether the base_url matches the request url.
    # The base_url can be a string, regex or nil. String and
    # regexp were checked, nil is always true. Else false.
    #
    # Nil serves as a placeholder in case you want to match
    # all urls.
    def url_match?(request_url)
      case base_url
      when String
        base_url == request_url
      when Regexp
        !!request_url.match(base_url)
      when nil
        true
      else
        false
      end
    end
  end
end
