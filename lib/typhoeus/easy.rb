module Typhoeus
  class Easy
    attr_reader :response_body, :response_header, :method, :headers, :url
    attr_accessor :start_time

    CURLINFO_STRING = 1048576
    OPTION_VALUES = {
      :CURLOPT_URL            => 10002,
      :CURLOPT_HTTPGET        => 80,
      :CURLOPT_HTTPPOST       => 10024,
      :CURLOPT_UPLOAD         => 46,
      :CURLOPT_CUSTOMREQUEST  => 10036,
      :CURLOPT_POSTFIELDS     => 10015,
      :CURLOPT_POSTFIELDSIZE  => 60,
      :CURLOPT_USERAGENT      => 10018,
      :CURLOPT_TIMEOUT_MS     => 155,
      :CURLOPT_NOSIGNAL       => 99,
      :CURLOPT_HTTPHEADER     => 10023,
      :CURLOPT_FOLLOWLOCATION => 52,
      :CURLOPT_MAXREDIRS      => 68,
      :CURLOPT_HTTPAUTH       => 107,
      :CURLOPT_USERPWD        => 10000 + 5,
      :CURLOPT_VERBOSE        => 41,
      :CURLOPT_PROXY          => 10004,
      :CURLOPT_VERIFYPEER     => 64,
      :CURLOPT_NOBODY         => 44
    }
    INFO_VALUES = {
      :CURLINFO_RESPONSE_CODE => 2097154,
      :CURLINFO_TOTAL_TIME    => 3145731,
      :CURLINFO_HTTPAUTH_AVAIL => 0x200000 + 23
    }
    AUTH_TYPES = {
      :CURLAUTH_BASIC         => 1,
      :CURLAUTH_DIGEST        => 2,
      :CURLAUTH_GSSNEGOTIATE  => 4,
      :CURLAUTH_NTLM          => 8,
      :CURLAUTH_DIGEST_IE     => 16
    }

    def initialize
      @method = :get
      @post_dat_set = nil
      @headers = {}
    end

    def headers=(hash)
      @headers = hash
    end

    def proxy=(proxy)
      set_option(OPTION_VALUES[:CURLOPT_PROXY], proxy)
    end

    def auth=(authinfo)
      set_option(OPTION_VALUES[:CURLOPT_USERPWD], "#{authinfo[:username]}:#{authinfo[:password]}")
      set_option(OPTION_VALUES[:CURLOPT_HTTPAUTH], authinfo[:method]) if authinfo[:method]
    end

    def auth_methods
      get_info_long(INFO_VALUES[:CURLINFO_HTTPAUTH_AVAIL])
    end

    def verbose=(boolean)
      set_option(OPTION_VALUES[:CURLOPT_VERBOSE], !!boolean ? 1 : 0)
    end

    def total_time_taken
      get_info_double(INFO_VALUES[:CURLINFO_TOTAL_TIME])
    end

    def response_code
      get_info_long(INFO_VALUES[:CURLINFO_RESPONSE_CODE])
    end

    def follow_location=(boolean)
      if boolean
        set_option(OPTION_VALUES[:CURLOPT_FOLLOWLOCATION], 1)
      else
        set_option(OPTION_VALUES[:CURLOPT_FOLLOWLOCATION], 0)
      end
    end

    def max_redirects=(redirects)
      set_option(OPTION_VALUES[:CURLOPT_MAXREDIRS], redirects)
    end

    def timeout=(milliseconds)
      @timeout = milliseconds
      set_option(OPTION_VALUES[:CURLOPT_NOSIGNAL], 1)
      set_option(OPTION_VALUES[:CURLOPT_TIMEOUT_MS], milliseconds)
    end

    def timed_out?
      @timeout && total_time_taken > @timeout && response_code == 0
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
      @url = url
      set_option(OPTION_VALUES[:CURLOPT_URL], url)
    end

    def disable_ssl_peer_verification
      set_option(OPTION_VALUES[:CURLOPT_VERIFYPEER], 0)
    end

    def method=(method)
      @method = method
      if method == :get
        set_option(OPTION_VALUES[:CURLOPT_HTTPGET], 1)
      elsif method == :post
        set_option(OPTION_VALUES[:CURLOPT_HTTPPOST], 1)
        self.post_data = ""
      elsif method == :put
        set_option(OPTION_VALUES[:CURLOPT_UPLOAD], 1)
        self.request_body = "" unless @request_body
      elsif method == :head
        set_option(OPTION_VALUES[:CURLOPT_NOBODY], 1)
      else
        set_option(OPTION_VALUES[:CURLOPT_CUSTOMREQUEST], "DELETE")
      end
    end

    def post_data=(data)
      @post_data_set = true
      set_option(OPTION_VALUES[:CURLOPT_POSTFIELDS], data)
      set_option(OPTION_VALUES[:CURLOPT_POSTFIELDSIZE], data.length)
    end

    def params=(params)
      params_string = params.keys.collect do |k|
        value = params[k]
        if value.is_a? Hash
          value.keys.collect {|sk| Rack::Utils.escape("#{k}[#{sk}]") + "=" + Rack::Utils.escape(value[sk].to_s)}
        elsif value.is_a? Array
          key = Rack::Utils.escape(k.to_s)
          value.collect { |v| "#{key}=#{Rack::Utils.escape(v.to_s)}" }.join('&')
        else
          "#{Rack::Utils.escape(k.to_s)}=#{Rack::Utils.escape(params[k].to_s)}"
        end
      end.flatten.join("&")

      if method == :post
        self.post_data = params_string
      else
        self.url = "#{url}?#{params_string}"
      end
    end

    def set_option(option, value)
      if value.class == String
        easy_setopt_string(option, value)
      else
        easy_setopt_long(option, value)
      end
    end

    def perform
      set_headers()
      easy_perform()
      response_code()
    end

    def set_headers
      headers.each_pair do |key, value|
        easy_add_header("#{key}: #{value}")
      end
      easy_set_headers() unless headers.empty?
    end

    # gets called when finished and response code is 200-299
    def success
      @success.call(self) if @success
    end

    def on_success(&block)
      @success = block
    end

    def on_success=(block)
      @success = block
    end

    # gets called when finished and response code is 300-599
    def failure
      @failure.call(self) if @failure
    end

    def on_failure(&block)
      @failure = block
    end

    def on_failure=(block)
      @failure = block
    end

    def retries
      @retries ||= 0
    end

    def increment_retries
      @retries ||= 0
      @retries += 1
    end

    def max_retries
      @max_retries ||= 40
    end

    def max_retries?
      retries >= max_retries
    end

    def reset
      @retries = 0
      @response_code = 0
      @response_header = ""
      @response_body = ""
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

    def curl_version
      version
    end
  end
end
