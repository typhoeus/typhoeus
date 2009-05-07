module Typhoeus
  class Response
    attr_reader :code, :headers, :body, :time
    
    def initialize(response_code, response_headers, response_body, request_time)
      @code    = response_code
      @headers = response_headers
      @body    = response_body
      @time    = request_time
    end
  end
end