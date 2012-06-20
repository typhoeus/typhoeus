module Typhoeus
  class Response
    attr_accessor :request, :mock, :options
    attr_writer :headers_hash

    def initialize(options = {})
      @options = options
    end

    (
      Ethon::Easies::Informations::AVAILABLE_INFORMATIONS.keys+[:return_code, :response_body, :response_headers]
    ).each do |name|
      define_method(name) do
        options[name.to_sym]
      end
    end

    LEGACY_MAPPING = {
      :body => :response_body,
      :headers => :response_headers,
      :code => :response_code,
      :curl_return_code => :return_code,
      :time => :total_time,
      :app_connect_time => :appconnect_time,
      :start_transfer_time => :starttransfer_time,
      :name_lookup_time => :namelookup_time
    }

    LEGACY_MAPPING.each do |old, new|
      eval("alias #{old} #{new}")
    end

    # Returns true if this is a mock response.
    def mock?
      options[:mock] || false
    end

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

    private

    def first_header_line
      @first_header_line ||= response_headers.to_s.split("\n").first
    end
  end
end
