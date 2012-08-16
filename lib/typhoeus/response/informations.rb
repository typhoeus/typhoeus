module Typhoeus
  class Response

    # This module contains logic about informations
    # on a response.
    module Informations

      # All available informations.
      AVAILABLE_INFORMATIONS = Ethon::Easies::Informations::AVAILABLE_INFORMATIONS.keys+
        [:return_code, :response_body, :response_header]

      AVAILABLE_INFORMATIONS.each do |name|
        define_method(name) do
          options[name.to_sym]
        end
      end

      # Returns the response header.
      #
      # @example Return header.
      #   response.header
      #
      # @return [ Header ] The response header.
      def header
        return nil if response_header.nil? && @header.nil?
        @header ||= Response::Header.new(response_header.split("\r\n\r\n").last)
      end

      # Return all redirections in between as multiple
      # responses with header.
      #
      # @example Return redirections.
      #   response.redirections
      #
      # @return [ Array ] The redirections
      def redirections
        return [] unless response_header
        response_header.split("\r\n\r\n")[0..-2].map{ |h| Response.new(:response_header => h) }
      end
    end
  end
end

