module Typhoeus
  class Easy
    attr_reader :response_body, :response_header, :method, :headers, :url, :params, :ssl_version, :handle, :header_list
    attr_accessor :start_time

    OPTION_VALUES = Curl::Option.to_hash.dup
    Curl::Option.to_hash.each {|key, value| OPTION_VALUES["CURLOPT_#{key.to_s.upcase}".to_sym] = value }
    INFO_VALUES = Curl::Info.to_hash.dup
    Curl::Info.to_hash.each {|key, value| INFO_VALUES["CURLINFO_#{key.to_s.upcase}".to_sym] = value }
    AUTH_TYPES = Curl::Auth.to_hash.dup
    Curl::Auth.to_hash.each {|key, value| AUTH_TYPES["CURLAUTH_#{key.to_s.upcase}".to_sym] = value }
    PROXY_TYPES = Curl::Proxy.to_hash.dup
    Curl::Proxy.to_hash.each {|key, value| PROXY_TYPES["CURLPROXY_#{key.to_s.upcase}".to_sym] = value }
    SSL_VERSIONS = Curl::SSLVersion.to_hash.dup
    Curl::SSLVersion.to_hash.each {|key, value| SSL_VERSIONS["CURL_SSLVERSION_#{key.to_s.upcase}".to_sym] = value }

    def initialize
      Curl.init

      @handle = Curl.easy_init

      @response_body = ""
      @response_header = ""
      @header_list = nil

      set_response_handlers

      @method = :get
      @headers = {}

      set_defaults

      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    def self.finalizer(easy)
      proc {
        Curl.slist_free_all(easy.header_list) if easy.header_list
        Curl.easy_cleanup(easy.handle)
      }
    end

    def set_response_handlers
      @body_write_callback = proc {|stream, size, num, object|
        @response_body << stream.read_string(size * num)
        size * num
      }
      set_option(:writefunction, @body_write_callback)

      @header_write_callback = proc {|stream, size, num, object|
        @response_header << stream.read_string(size * num)
        size * num
      }
      set_option(:headerfunction, @header_write_callback)
    end

    def set_defaults
      # Enable encoding/compression support
      self.encoding = ''
      self.ssl_version = :default
    end

    def encoding=(encoding)
      # Enable encoding/compression support
      set_option(:encoding, encoding)
    end

    def ssl_version=(version)
      raise "Invalid SSL version: '#{version}' supplied! Please supply one as listed in Typhoeus::Easy::SSL_VERSIONS" unless SSL_VERSIONS.has_key?(version)
      @ssl_version = version

      set_option(:sslversion, SSL_VERSIONS[version])
    end

    def headers=(hash)
      @headers = hash
    end

    def interface=(interface)
      @interface = interface
      set_option(:interface, interface)
    end

    def proxy=(proxy)
      set_option(:proxy, proxy[:server])
      set_option(:proxytype, PROXY_TYPES.has_key?(proxy[:type]) ? PROXY_TYPES[proxy[:type]] : proxy[:type]) if proxy[:type]
    end

    def proxy_auth=(authinfo)
      set_option(:proxyuserpwd, "#{authinfo[:username]}:#{authinfo[:password]}")
      set_option(:proxyauth, AUTH_TYPES.has_key?(authinfo[:method]) ? AUTH_TYPES[authinfo[:method]] : authinfo[:method]) if authinfo[:method]
    end

    def auth=(authinfo)
      set_option(:userpwd, "#{authinfo[:username]}:#{authinfo[:password]}")
      set_option(:httpauth, AUTH_TYPES.has_key?(authinfo[:method]) ? AUTH_TYPES[authinfo[:method]] : authinfo[:method]) if authinfo[:method]
    end

    def auth_methods
      get_info_long(:httpauth_avail)
    end

    def verbose=(boolean)
      set_option(:verbose, !!boolean ? 1 : 0)
    end

    def total_time_taken
      get_info_double(:total_time)
    end

    def start_transfer_time
      get_info_double(:starttransfer_time)
    end

    def app_connect_time
      get_info_double(:appconnect_time)
    end

    def pretransfer_time
      get_info_double(:pretransfer_time)
    end

    def connect_time
      get_info_double(:connect_time)
    end

    def name_lookup_time
      get_info_double(:namelookup_time)
    end

    def effective_url
      get_info_string(:effective_url)
    end

    def primary_ip
      get_info_string(:primary_ip)
    end

    def response_code
      get_info_long(:response_code)
    end

    def follow_location=(boolean)
      if boolean
        set_option(:followlocation, 1)
      else
        set_option(:followlocation, 0)
      end
    end

    def max_redirects=(redirects)
      set_option(:maxredirs, redirects)
    end

    def connect_timeout=(milliseconds)
      @connect_timeout = milliseconds
      set_option(:nosignal, 1)
      set_option(:connecttimeout_ms, milliseconds)
    end

    def timeout=(milliseconds)
      @timeout = milliseconds
      set_option(:nosignal, 1)
      set_option(:timeout_ms, milliseconds)
    end

    def timed_out?
      @curl_return_code == :operation_timedout
    end

    def supports_zlib?
      !!(curl_version.match(/zlib/))
    end

    def request_body=(request_body)
      @request_body = request_body
      if @method == :put
        @request_body_read = 0
        set_option(:infilesize, Utils.bytesize(@request_body))

        @read_callback = proc {|stream, size, num, object|
          size = size * num
          left = Utils.bytesize(@request_body) - @request_body_read
          size = left if size > left
          if size > 0
            stream.write_string(Utils.byteslice(@request_body, @request_body_read, size), size)
            @request_body_read += size
          end
          size
        }
        set_option(:readfunction, @read_callback)
      else
        self.post_data = request_body
      end
    end

    def user_agent=(user_agent)
      set_option(:useragent, user_agent)
    end

    def url=(url)
      @url = url
      set_option(:url, url)
    end

    def disable_ssl_peer_verification
      set_option(:verifypeer, 0)
    end

    def disable_ssl_host_verification
      set_option(:verifyhost, 0)
    end

    def method=(method)
      @method = method
      if method == :get
        set_option(:httpget, 1)
      elsif method == :post
        set_option(:httppost, 1)
        self.post_data = ""
      elsif method == :put
        set_option(:upload, 1)
        self.request_body = @request_body.to_s
      elsif method == :head
        set_option(:nobody, 1)
      else
        set_option(:customrequest, method.to_s.upcase)
      end
    end

    def post_data=(data)
      @post_data_set = true
      set_option(:postfieldsize, Utils.bytesize(data))
      set_option(:copypostfields, data)
    end

    def params
      @form.nil? ? {} : @form.params
    end

    def params=(params)
      @form = Typhoeus::Form.new(params)

      if method == :post
        @form.process!
        if @form.multipart?
          set_option(:httppost, @form)
        else
          self.post_data = @form.to_s
        end
      else
        self.url = "#{url}?#{@form.to_s}"
      end
    end

    # Set SSL certificate
    # " The string should be the file name of your certificate. "
    # The default format is "PEM" and can be changed with ssl_cert_type=
    def ssl_cert=(cert)
      set_option(:sslcert, cert)
    end

    # Set SSL certificate type
    # " The string should be the format of your certificate. Supported formats are "PEM" and "DER" "
    def ssl_cert_type=(cert_type)
      raise "Invalid ssl cert type : '#{cert_type}'..." if cert_type and !%w(PEM DER p12).include?(cert_type)
      set_option(:sslcerttype, cert_type)
    end

    # Set SSL Key file
    # " The string should be the file name of your private key. "
    # The default format is "PEM" and can be changed with ssl_key_type=
    #
    def ssl_key=(key)
      set_option(:sslkey, key)
    end

    # Set SSL Key type
    # " The string should be the format of your private key. Supported formats are "PEM", "DER" and "ENG". "
    #
    def ssl_key_type=(key_type)
      raise "Invalid ssl key type : '#{key_type}'..." if key_type and !%w(PEM DER ENG).include?(key_type)
      set_option(:sslkeytype, key_type)
    end

    def ssl_key_password=(key_password)
      set_option(:keypasswd, key_password)
    end

    # Set SSL CACERT
    # " File holding one or more certificates to verify the peer with. "
    #
    def ssl_cacert=(cacert)
      set_option(:cainfo, cacert)
    end

    # Set CAPATH
    # " directory holding multiple CA certificates to verify the peer with. The certificate directory must be prepared using the openssl c_rehash utility. "
    #
    def ssl_capath=(capath)
      set_option(:capath, capath)
    end

    def set_option(option, value)
      case value
        when String
          Curl.easy_setopt_string(@handle, option, value.to_s)
        when Integer
          Curl.easy_setopt_long(@handle, option, value)
        when Proc, FFI::Function
          Curl.easy_setopt_callback(@handle, option, value)
        when Typhoeus::Form
          Curl.easy_setopt(@handle, option, value.first.read_pointer)
        else
          Curl.easy_setopt(@handle, option, value) if value
      end
    end

    def perform
      set_headers()
      @curl_return_code = Curl.easy_perform(@handle)
      resp_code = response_code()
      if resp_code >= 200 && resp_code <= 299
        success
      else
        failure
      end
      resp_code
    end

    def set_headers
      @header_list = nil
      headers.each {|key, value| @header_list = Curl.slist_append(@header_list, "#{key}: #{value}") }
      set_option(:httpheader, @header_list) unless headers.empty?
    end

    # gets called when finished and response code is not 2xx,
    # or curl returns an error code.
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
    # or curl returns an error code
    def failure
      @failure.call(self) if @failure
    end

    def on_failure(&block)
      @failure = block
    end

    def on_failure=(block)
      @failure = block
    end

    def reset
      @response_code = 0
      @response_header = ""
      @response_body = ""
      @request_body = ""

      if @header_list
        Curl.slist_free_all(@header_list)
        @header_list = nil
      end

      Curl.easy_reset(@handle)
      set_response_handlers

      set_defaults
    end

    def get_info_string(option)
      string = FFI::MemoryPointer.new(:pointer)
      if Curl.easy_getinfo(@handle, option, string) == :ok
        string.read_pointer.read_string
      else nil
      end
    end

    def get_info_long(option)
      long = FFI::MemoryPointer.new(:long)
      if Curl.easy_getinfo(@handle, option, long) == :ok
        long.read_long
      else nil
      end
    end

    def get_info_double(option)
      double = FFI::MemoryPointer.new(:double)
      if Curl.easy_getinfo(@handle, option, double) == :ok
        double.read_double
      else nil
      end
    end

    def curl_return_code
      Curl::EasyCode[@curl_return_code]
    end

    def curl_return_code=(code)
     @curl_return_code = (code.class == Symbol ? code : Curl::EasyCode[code])
    end

    def curl_error_message(code = @curl_return_code)
      code ? Curl.easy_strerror(code) : nil
    end

    def escape(data, size = Utils.bytesize(data))
      Curl.easy_escape(@handle, data, size)
    end

    def curl_version
      Curl.version
    end
  end
end
