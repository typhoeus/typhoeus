module Typhoeus
  module Requests
    module Stubbable
      def run
        if expectation = Expectation.find_by(self)
          @response = expectation.response
          @response.mock = true
          execute_callbacks
          @response
        else
          super
        end
      end
    end
  end
end
