require 'typhoeus/easy/ffi'
require 'typhoeus/easy/options'
require 'typhoeus/easy/ssl'
require 'typhoeus/easy/auth'
require 'typhoeus/easy/proxy'
require 'typhoeus/easy/callbacks'
require 'typhoeus/easy/infos'

module Typhoeus
  class Easy
    include Typhoeus::EasyFu::FFI
    include Typhoeus::EasyFu::Options
    include Typhoeus::EasyFu::SSL
    include Typhoeus::EasyFu::Auth
    include Typhoeus::EasyFu::Proxy
    include Typhoeus::EasyFu::Callbacks
    include Typhoeus::EasyFu::Infos

    attr_reader :url, :header_list
    attr_accessor :start_time

    def initialize
      Curl.init

      set_response_handlers
      set_defaults

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

    def set_defaults
      # Enable encoding/compression support
      self.encoding = ''
      self.ssl_version = :default
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

    def reset
      @response_code = 0
      @response_header = ""
      @response_body = ""
      @request_body = ""

      if @header_list
        Curl.slist_free_all(@header_list)
        @header_list = nil
      end

      Curl.easy_reset(handle)
      set_response_handlers

      set_defaults
    end

    def curl_return_code=(code)
      @curl_return_code = (code.class == Symbol ? code : Curl::EasyCode[code])
    end
  end
end
