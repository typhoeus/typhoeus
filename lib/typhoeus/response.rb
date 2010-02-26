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
    
    def headers_hash
      headers.split("\n").map {|o| o.strip}.inject({}) do |hash, o|
        if o.empty?
          hash
        else
          i = o.index(":") || o.size
          key = o.slice(0, i)
          value = o.slice(i + 1, o.size)
          value = value.strip unless value.nil?
          if hash.has_key? key
            hash[key] = [hash[key], value].flatten
          else
            hash[key] = value
          end
          
          hash
        end
      end
    end
  end
end
