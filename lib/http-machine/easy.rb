module HTTPMachine
  class Easy
    attr_reader :response_body, :response_header, :method, :headers
    CURLINFO_STRING = 1048576
    OPTION_VALUES = {
      :CURLOPT_URL           => 10002,
      :CURLOPT_HTTPGET       => 80,
      :CURLOPT_HTTPPOST      => 10024,
      :CURLOPT_UPLOAD        => 46,
      :CURLOPT_CUSTOMREQUEST => 10036,
      :CURLOPT_POSTFIELDS    => 10015,
      :CURLOPT_POSTFIELDSIZE => 60,
      :CURLOPT_USERAGENT     => 10018,
      :CURLOPT_TIMEOUT_MS    => 155,
      :CURLOPT_NOSIGNAL      => 99,
      :CURLOPT_HTTPHEADER    => 10023
    }
    INFO_VALUES = {
      :CURLINFO_RESPONSE_CODE => 2097154
    }
    
    def initialize
      @method = :get
      @post_dat_set = nil
      @headers = {}
    end
    
    def response_code
      get_info_long(INFO_VALUES[:CURLINFO_RESPONSE_CODE])
    end
    
    def timeout=(milliseconds)
      set_option(OPTION_VALUES[:CURLOPT_NOSIGNAL], 1)
      set_option(OPTION_VALUES[:CURLOPT_TIMEOUT_MS], milliseconds)
    end
    
    def request_body=(request_body)
      @request_body = request_body
      if @method == :put
        easy_set_request_body(@request_body)
        headers["Transfer-Encoding"] = ""
        headers["Expect"] = ""
      else
        self.post_data = request_body
      end
    end
    
    def user_agent=(user_agent)
      set_option(OPTION_VALUES[:CURLOPT_USERAGENT], user_agent)
    end
          
    def url=(url)
      set_option(OPTION_VALUES[:CURLOPT_URL], url)
    end
    
    def method=(method)
      @method = method
      if method == :get
        set_option(OPTION_VALUES[:CURLOPT_HTTPGET], 1)
      elsif method == :post
        set_option(OPTION_VALUES[:CURLOPT_HTTPPOST], 1)
      elsif method == :put
        set_option(OPTION_VALUES[:CURLOPT_UPLOAD], 1)
      else
        set_option(OPTION_VALUES[:CURLOPT_CUSTOMREQUEST], "DELETE")
      end
    end
    
    def post_data=(data)
      @post_data_set = true
      set_option(OPTION_VALUES[:CURLOPT_POSTFIELDS], data)
      set_option(OPTION_VALUES[:CURLOPT_POSTFIELDSIZE], data.length)
    end
    
    def set_option(option, value)
      if value.class == String
        easy_setopt_string(option, value)
      else
        easy_setopt_long(option, value)
      end
    end
    
    def perform
      self.post_data = "" if (@method == :post && @post_data_set.nil?)
      headers.each_pair do |key, value|
        easy_add_header("#{key}: #{value}")
      end
      easy_set_headers() unless headers.empty?
      easy_perform()
      response_code()
    end
    
    def reset
      easy_reset()
    end
    
    def get_info_string(option)
      easy_getinfo_string(option)
    end
    
    def get_info_long(option)
      easy_getinfo_long(option)
    end
    
    def get_info_double(option)
      easy_getinfo_double(option)
    end
  end
end