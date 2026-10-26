# frozen_string_literal: true

module Typhoeus
  class Response

    # This module contains logic about informations
    # on a response.
    module Informations

      # Return libcurls return value.
      #
      # @example Get return_code.
      #   response.return_code
      #
      # @return [ Symbol ] The return_code.
      def return_code
        options[:return_code]
      end

      # Returns a string describing the return.
      #
      # @example Get return_message.
      #   response.return_message
      #
      # @return [ String ] The return_message.
      #
      # @since 0.6.2
      def return_message
        Ethon::Curl.easy_strerror(return_code) if return_code
      end

      # Returns the detailed error message from libcurl's error buffer,
      # only available when the request was made with errorbuffer: true.
      #
      # @example Get error_message.
      #   response.error_message
      #
      # @return [ String, nil ] The error_message.
      def error_message
        options[:error_message]
      end

      # Return the http response body.
      #
      # @example Get response_body.
      #   response.response_body
      #
      # @return [ String ] The response_body.
      def response_body
        body = options[:response_body] || options[:body]
        apply_content_type_charset(body)
      end
      alias :body :response_body

      # Return the http response headers.
      #
      # @example Get response_headers.
      #   response.response_headers
      #
      # @return [ String ] The response_headers.
      def response_headers
        return options[:response_headers] if options[:response_headers]
        if mock? && h = options[:headers]
          status_code = options[:response_code] || options[:code] || 200
          reason_phrase = status_code.to_i == 200 ? "OK" : "Mock Reason Phrase"
          status_line = "HTTP/1.1 #{status_code} #{reason_phrase}"
          actual_headers = h.map{ |k,v| [k, v.respond_to?(:join) ? v.join(',') : v] }.
            map{ |e| "#{e.first}: #{e.last}" }

          [status_line, *actual_headers].join("\r\n")
        end
      end

      # Return the last received HTTP, FTP or SMTP response code.
      # The value will be zero if no server response code has
      # been received. Note that a proxy's CONNECT response should
      # be read with http_connect_code and not this.
      #
      # @example Get response_code.
      #   response.response_code
      #
      # @return [ Integer ] The response_code.
      def response_code
        code = options[:response_code] || options[:code]
        return code.to_i unless code.nil?

        # A response built from raw headers, such as one returned by
        # #redirections, has no option describing the status.
        line = first_header_line
        status = line && line[/\AHTTP\/\S+\s+(\d{3})/, 1]
        status ? status.to_i : 0
      end
      alias :code :response_code

      # Return the available http auth methods.
      # Bitmask indicating the authentication method(s)
      # available.
      #
      # @example Get httpauth_avail.
      #   response.httpauth_avail
      #
      # @return [ Integer ] The bitmask.
      def httpauth_avail
        options[:httpauth_avail]
      end


      # Return the total time in seconds for the previous
      # transfer, including name resolving, TCP connect etc.
      #
      # @example Get total_time.
      #   response.total_time
      #
      # @return [ Float ] The total_time.
      def total_time
        options[:total_time] || options[:time]
      end
      alias :time :total_time

      # Return the time, in seconds, it took from the start
      # until the first byte is received by libcurl. This
      # includes pretransfer time and also the time the
      # server needs to calculate the result.
      #
      # @example Get starttransfer_time.
      #   response.starttransfer_time
      #
      # @return [ Float ] The starttransfer_time.
      def starttransfer_time
        options[:starttransfer_time] || options[:start_transfer_time]
      end
      alias :start_transfer_time :starttransfer_time

      # Return the time, in seconds, it took from the start
      # until the SSL/SSH connect/handshake to the remote
      # host was completed. This time is most often very near
      # to the pre transfer time, except for cases such as HTTP
      # pipelining where the pretransfer time can be delayed
      # due to waits in line for the pipeline and more.
      #
      # @example Get appconnect_time.
      #   response.appconnect_time
      #
      # @return [ Float ] The appconnect_time.
      def appconnect_time
        options[:appconnect_time] || options[:app_connect_time]
      end
      alias :app_connect_time :appconnect_time

      # Return the time, in seconds, it took from the start
      # until the file transfer is just about to begin. This
      # includes all pre-transfer commands and negotiations
      # that are specific to the particular protocol(s) involved.
      # It does not involve the sending of the protocol-
      # specific request that triggers a transfer.
      #
      # @example Get pretransfer_time.
      #  response.pretransfer_time
      #
      # @return [ Float ] The pretransfer_time.
      def pretransfer_time
        options[:pretransfer_time]
      end

      # Return the time, in seconds, it took from the start
      # until the connect to the remote host (or proxy) was completed.
      #
      # @example Get connect_time.
      #   response.connect_time
      #
      # @return [ Float ] The connect_time.
      def connect_time
        options[:connect_time]
      end

      # Return the time, in seconds, it took from the
      # start until the name resolving was completed.
      #
      # @example Get namelookup_time.
      #   response.namelookup_time
      #
      # @return [ Float ] The namelookup_time.
      def namelookup_time
        options[:namelookup_time] || options[:name_lookup_time]
      end
      alias :name_lookup_time :namelookup_time

      # Return the time, in seconds, it took for all redirection steps
      # include name lookup, connect, pretransfer and transfer before the
      # final transaction was started. time_redirect shows the complete
      # execution time for multiple redirections.
      #
      # @example Get redirect_time.
      #   response.redirect_time
      #
      # @return [ Float ] The redirect_time.
      def redirect_time
        options[:redirect_time]
      end

      # Return the last used effective url.
      #
      # @example Get effective_url.
      #   response.effective_url
      #
      # @return [ String ] The effective_url.
      def effective_url
        options[:effective_url]
      end

      # Return the string holding the IP address of the most recent
      # connection done with this curl handle. This string
      # may be IPv6 if that's enabled.
      #
      # @example Get primary_ip.
      #   response.primary_ip
      #
      # @return [ String ] The primary_ip.
      def primary_ip
        options[:primary_ip]
      end

      # Return the total number of redirections that were
      # actually followed
      #
      # @example Get redirect_count.
      #   response.redirect_count
      #
      # @return [ Integer ] The redirect_count.
      def redirect_count
        options[:redirect_count]
      end

      # Return the URL a redirect would take you to, had you enabled redirects.
      #
      # @example Get redirect_url.
      #   response.redirect_url
      #
      # @return [ String ] The redirect_url.
      def redirect_url
        options[:redirect_url]
      end

      def request_size
        options[:request_size]
      end

      # Return the bytes, the total amount of bytes that were uploaded
      #
      # @example Get size_upload.
      #   response.size_upload
      #
      # @return [ Float ] The size_upload.
      def size_upload
        options[:size_upload]
      end


      # Return the bytes, the total amount of bytes that were downloaded.
      # The amount is only for the latest transfer and will be reset again
      # for each new transfer. This counts actual payload data, what's
      # also commonly called body. All meta and header data are excluded
      # and will not be counted in this number.
      #
      # @example Get size_download
      #   response.size_download
      #
      # @return [ Float ] The size_download.
      def size_download
        options[:size_download]
      end

      # Return the bytes/second, the average upload speed that curl
      # measured for the complete upload
      #
      # @example Get speed_upload.
      #   response.speed_upload
      #
      # @return [ Float ] The speed_upload.
      def speed_upload
        options[:speed_upload]
      end

      # Return the bytes/second, the average download speed that curl
      # measured for the complete download
      #
      # @example Get speed_download.
      #   response.speed_download
      #
      # @return [ Float ] The speed_download.
      def speed_download
        options[:speed_download]
      end

      def debug_info
        options[:debug_info]
      end

      # Returns the response header.
      #
      # @example Return headers.
      #   response.headers
      #
      # @return [ Typhoeus::Header ] The response header.
      def headers
        return @headers if defined?(@headers) && @headers
        return nil if response_headers.nil?
        @headers = Header.new(last_response_block)
      end
      alias :headers_hash :headers

      # Return all redirections in between as multiple
      # responses with header.
      #
      # @example Return redirections.
      #   response.redirections
      #
      # @return [ Array<Typhoeus::Response> ] The redirections
      def redirections
        return [] unless response_headers

        http_blocks = response_blocks.select { |block| block.start_with?("HTTP/") }
        blocks = http_blocks.empty? ? response_blocks[0..-2] : http_blocks[0..-2]
        blocks.map { |header| Response.new(:response_headers => header) }
      end

      private

      # Split the raw response headers into their header blocks.
      #
      # @return [ Array<String> ] The blocks.
      def response_blocks
        response_headers.to_s.split("\r\n\r\n")
      end

      # Return the last block that starts a new response. HTTP/1.1 trailers
      # add a block without a status line after the response headers.
      #
      # @return [ String ] The response block.
      def last_response_block
        http_blocks = response_blocks.select { |block| block.start_with?("HTTP/") }
        (http_blocks.empty? ? response_blocks.last : http_blocks.last).to_s
      end

      # Force the body to the charset advertised by the Content-Type
      # header, but leave binary and already encoded bodies alone.
      #
      # @param [ String, nil ] body The response body.
      #
      # @return [ String, nil ] The response body.
      def apply_content_type_charset(body)
        return body unless body.is_a?(String) && !body.frozen?
        return body unless body.encoding == Encoding::BINARY

        content_type = headers && headers["Content-Type"]
        return body unless content_type

        charset = content_type.to_s[/;\s*charset\s*=\s*["']?([^"';,\s]+)/i, 1]
        return body unless charset

        body.force_encoding(Encoding.find(charset))
      rescue ArgumentError
        body
      end
    end
  end
end

