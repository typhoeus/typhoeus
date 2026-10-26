# frozen_string_literal: true

require 'typhoeus/errors/typhoeus_error'

module Typhoeus
  module Errors

    # Raised when a request matches a stub that does not provide a usable
    # response.
    class NoResponse < TyphoeusError
      def initialize(base_url, reason = nil)
        message = "No response defined for stub: #{base_url.inspect}"
        message = "#{message} (#{reason})" if reason
        super(message)
      end
    end
  end
end
