module Typhoeus
  module Responses
    module Status
      def status_message
        return @status_message if @status_message

        # HTTP servers can choose not to include the explanation to HTTP codes. The RFC
        # states this (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4):
        # Except when responding to a HEAD request, the server SHOULD include an entity containing
        # an explanation of the error situation [...]
        # This means 'HTTP/1.1 404' is as valid as 'HTTP/1.1 404 Not Found' and we have to handle it.

        # Regexp doc: http://rubular.com/r/eAr1oVYsVa
        if first_header_line != nil and first_header_line[/\d{3} (.*)$/, 1] != nil
          @status_message = first_header_line[/\d{3} (.*)$/, 1].chomp
        else
          @status_message = nil
        end
      end

      def http_version
        @http_version ||= first_header_line ? first_header_line[/HTTP\/(\S+)/, 1] : nil
      end

      def success?
        (200..299).include?(response_code)
      end

      def modified?
        response_code != 304
      end

      def timed_out?
        return_code == 28
      end

      def first_header_line
        @first_header_line ||= response_headers.to_s.split("\n").first
      end
    end
  end
end
