require 'typhoeus/easy/ffi_helper'
require 'typhoeus/easy/options'
require 'typhoeus/easy/ssl'
require 'typhoeus/easy/auth'
require 'typhoeus/easy/proxy'
require 'typhoeus/easy/callbacks'
require 'typhoeus/easy/infos'

module Typhoeus
  class Easy
    include Typhoeus::EasyFu::FFIHelper
    include Typhoeus::EasyFu::Options
    include Typhoeus::EasyFu::SSL
    include Typhoeus::EasyFu::Auth
    include Typhoeus::EasyFu::Proxy
    include Typhoeus::EasyFu::Callbacks
    include Typhoeus::EasyFu::Infos

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

    attr_reader :url, :header_list
    attr_accessor :start_time

    def initialize
      Curl.init
      reset(true)
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    def method
      @method ||= :get
    end

    def headers
      @header ||= {}
    end

    def response_body
      @response_body ||= ""
    end

    def response_header
      @response_header ||= ""
    end

    def headers=(hash)
      @headers = hash
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

    def perform
      set_headers()
      @curl_return_code = Curl.easy_perform(handle)
      resp_code = response_code()
      if resp_code >= 200 && resp_code <= 299
        success
      else
        failure
      end
      resp_code
    end

    def reset(fresh = nil)
      unless fresh
        @response_code = 0
        @response_header = ""
        @response_body = ""
        @request_body = ""

        if @header_list
          Curl.slist_free_all(@header_list)
          @header_list = nil
        end

        Curl.easy_reset(handle)
      end

      self.write_function = body_write_callback
      self.header_function = header_write_callback
      self.encoding = ''
      self.ssl_version = :default
    end

    def curl_return_code=(code)
      @curl_return_code = (code.class == Symbol ? code : Curl::EasyCode[code])
    end
  end
end
