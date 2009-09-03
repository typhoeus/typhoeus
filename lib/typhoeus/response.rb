module Typhoeus
  class Response
    attr_accessor :request
    attr_reader :code, :headers, :body, :time,
                :requested_url, :requested_remote_method,
                :requested_http_method, :start_time
    
    def initialize(params = {})
      @code                  = params[:code]
      @headers               = params[:headers]
      @body                  = params[:body]
      @time                  = params[:time]
      @requested_url         = params[:requested_url]
      @requested_http_method = params[:requested_http_method]
      @start_time            = params[:start_time]
      @request               = params[:request]
    end
  end
end
