module Typhoeus
  module Responses

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

      def header
        return nil unless response_header
        @header ||= Responses::Header.new(response_header.split("\r\n\r\n").last)
      end

      def redirections
        return [] unless response_header
        response_header.split("\r\n\r\n")[0..-2].map{ |h| Response.new(:response_header => h) }
      end
    end
  end
end

