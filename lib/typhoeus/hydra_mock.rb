module Typhoeus
  class HydraMock
    attr_reader :url, :method, :requests, :uri

    def initialize(url, method, options = {})
      @url      = url
      @uri      = URI.parse(url) if url.kind_of?(String)
      @method   = method
      @requests = []
      @options = options
      if @options[:headers]
        @options[:headers] = Typhoeus::LowercaseHash.new(@options[:headers])
      end

      @current_response_index = 0
    end

    def body
      @options[:body]
    end

    def body?
      @options.has_key?(:body)
    end

    def headers
      @options[:headers]
    end

    def headers?
      @options.has_key?(:headers)
    end

    def add_request(request)
      @requests << request
    end

    def and_return(val)
      if val.respond_to?(:each)
        @responses = val
      else
        @responses = [val]
      end

      # make sure to mark them as a mock.
      @responses.each { |r| r.mock = true }

      val
    end

    def response
      if @current_response_index == (@responses.length - 1)
        @responses.last
      else
        value = @responses[@current_response_index]
        @current_response_index += 1
        value
      end
    end

    def matches?(request)
      if !method_matches?(request) or !url_matches?(request)
        return false
      end

      if body?
        return false unless body_matches?(request)
      end

      if !headers_match?(request)
        return false
      end

      true
    end

  private
    def method_matches?(request)
      self.method == :any or self.method == request.method
    end

    def url_matches?(request)
      if url.kind_of?(String)
        request_uri = URI.parse(request.url)
        request_uri == self.uri
      else
        self.url =~ request.url
      end
    end

    def body_matches?(request)
      !request.body.nil? && !request.body.empty? && request.body == self.body
    end

    def headers_match?(request)
      if empty_headers?(self.headers)
        empty_headers?(request.headers)
      else
        return false if empty_headers?(request.headers)

        matches = 0
        request.headers.each do |key, value|
          matches += 1 if headers.has_key?(key) && header_value_matches?(key, value)
        end

        matches == self.headers.size
      end
    end

    def header_value_matches?(key, expected_value)
      if headers[key].class != expected_value.class
        false
      else
        if headers[key].is_a?(Array)
          headers[key].each do |value|
            return false unless expected_value.include?(value)
          end
          headers.size == expected_value.size
        else
          headers[key] === expected_value
        end
      end
    end

    def empty_headers?(headers)
      headers.nil? || headers.empty?
    end
  end
end
