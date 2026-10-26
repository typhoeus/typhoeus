# frozen_string_literal: true

module Typhoeus
  module Errors

    # Raises when block connection is turned on
    # and making a real request.
    class NoStub < TyphoeusError
      def initialize(request)
        url = begin
          request.url
        rescue StandardError
          request.base_url
        end
        super("The connection is blocked and no stub defined: #{url}")
      end
    end
  end
end
