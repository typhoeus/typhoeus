module Typhoeus
  module Requests
    module Responseable
      def response=(value)
        @response = value
      end

      def response
        @response ||= nil
      end
    end
  end
end
