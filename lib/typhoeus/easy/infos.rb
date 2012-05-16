module Typhoeus
  module EasyFu
    module Infos
      def get_info_string(option)
        if Curl.easy_getinfo(@handle, option, string_ptr) == :ok
          string_ptr.read_pointer.read_string
        else nil
        end
      end

      def get_info_long(option)
        if Curl.easy_getinfo(@handle, option, long_ptr) == :ok
          long_ptr.read_long
        else nil
        end
      end

      def get_info_double(option)
        if Curl.easy_getinfo(@handle, option, double_ptr) == :ok
          double_ptr.read_double
        else nil
        end
      end

      def auth_methods
        get_info_long(:httpauth_avail)
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

      def timed_out?
        @curl_return_code == :operation_timedout
      end

      def curl_return_code
        Curl::EasyCode[@curl_return_code]
      end

      def curl_error_message(code = @curl_return_code)
        code ? Curl.easy_strerror(code) : nil
      end

      def curl_version
        Curl.version
      end

      def supports_zlib?
        !!(curl_version.match(/zlib/))
      end
    end
  end
end
