module Typhoeus
  class Response
    attr_accessor :request
    attr_reader :code, :headers, :body, :time,
                :requested_url,
                :requested_http_method, :start_time,
                :effective_url, :start_transfer_time,
                :app_connect_time, :pretransfer_time,
                :connect_time, :name_lookup_time,
                :curl_return_code, :curl_error_message,
                :primary_ip

    attr_writer :headers_hash

    def initialize(params = {})
      @code                  = params[:code]
      @curl_return_code      = params[:curl_return_code]
      @curl_error_message    = params[:curl_error_message]
      @status_message        = params[:status_message]
      @http_version          = params[:http_version]
      @headers               = params[:headers]
      @body                  = params[:body]
      @time                  = params[:time]
      @requested_url         = params[:requested_url]
      @requested_http_method = params[:requested_http_method]
      @start_time            = params[:start_time]
      @start_transfer_time   = params[:start_transfer_time]
      @app_connect_time      = params[:app_connect_time]
      @pretransfer_time      = params[:pretransfer_time]
      @connect_time          = params[:connect_time]
      @name_lookup_time      = params[:name_lookup_time]
      @request               = params[:request]
      @effective_url         = params[:effective_url]
      @primary_ip            = params[:primary_ip]
      @headers_hash          = Header.new(params[:headers_hash]) if params[:headers_hash]
    end

    def headers
      @headers ||= @headers_hash ? construct_header_string : ''
    end

    def headers_hash
      @headers_hash ||= begin
        headers.split("\n").map {|o| o.strip}.inject(Typhoeus::Header.new) do |hash, o|
          if o.empty? || o =~ /^HTTP\/[\d\.]+/
            hash
          else
            i = o.index(":") || o.size
            key = o.slice(0, i)
            value = o.slice(i + 1, o.size)
            value = value.strip unless value.nil?
            if hash.key? key
              hash[key] = [hash[key], value].flatten
            else
              hash[key] = value
            end

            hash
          end
        end
      end
    end

    def status_message
      return @status_message if @status_message != nil

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
      @code >= 200 && @code < 300
    end

    def modified?
      @code != 304
    end

    def timed_out?
      curl_return_code == 28
    end

    private

      def first_header_line
        @first_header_line ||= @headers.to_s.split("\n").first
      end

      def construct_header_string
        lines = ["HTTP/#{http_version} #{code} #{status_message}"]

        @headers_hash.each do |key, values|
          [values].flatten.each do |value|
            lines << "#{key}: #{value}"
          end
        end

        lines << '' << ''
        lines.join("\r\n")
      end
  end
end
