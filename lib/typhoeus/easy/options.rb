module Typhoeus
  module EasyFu
    module Options
      def write_function=(callback)
        set_option(:writefunction, body_write_callback)
      end

      def header_function=(callback)
        set_option(:headerfunction, header_write_callback)
      end

      def encoding=(encoding)
        # Enable encoding/compression support
        set_option(:encoding, encoding)
      end

      def interface=(interface)
        @interface = interface
        set_option(:interface, interface)
      end

      def verbose=(boolean)
        set_option(:verbose, !!boolean ? 1 : 0)
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

      def request_body=(request_body)
        @request_body = request_body
        if method == :put
          @request_body_read = 0
          set_option(:infilesize, Utils.bytesize(@request_body))
          set_option(:readfunction, read_callback)
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

      def set_option(option, value)
        case value
        when String
          Curl.easy_setopt_string(handle, option, value.to_s)
        when Integer
          Curl.easy_setopt_long(handle, option, value)
        when Proc, ::FFI::Function
          Curl.easy_setopt_callback(handle, option, value)
        when Typhoeus::Form
          Curl.easy_setopt(handle, option, value.first.read_pointer)
        else
          Curl.easy_setopt(handle, option, value) if value
        end
      end

      def set_headers
        @header_list = nil
        headers.each {|key, value| @header_list = Curl.slist_append(@header_list, "#{key}: #{value}") }
        set_option(:httpheader, @header_list) unless headers.empty?
      end
    end
  end
end
