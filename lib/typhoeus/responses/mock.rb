module Typhoeus
  module Responses
    module Mock
      def mock?
        options[:mock] || false
      end
    end
  end
end
