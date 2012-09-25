module Typhoeus
  class Response

    # This module contains logic about informations
    # on a response.
    module Informations

      # All available informations.
      AVAILABLE_INFORMATIONS = Ethon::Easy::Informations::AVAILABLE_INFORMATIONS.keys+
        [:return_code, :response_body, :response_headers]

      AVAILABLE_INFORMATIONS.each do |name|
        define_method(name) do
          options[name.to_sym]
        end
      end

      # Returns the response header.
      #
      # @example Return headers.
      #   response.headers
      #
      # @return [ Header ] The response header.
      def headers
        return nil if response_headers.nil? && @headers.nil?
        @headers ||= Response::Header.new(response_headers.split("\r\n\r\n").last)
      end

      # Return all redirections in between as multiple
      # responses with header.
      #
      # @example Return redirections.
      #   response.redirections
      #
      # @return [ Array ] The redirections
      def redirections
        return [] unless response_headers
        response_headers.split("\r\n\r\n")[0..-2].map{ |h| Response.new(:response_headers => h) }
      end
    end
  end
end

