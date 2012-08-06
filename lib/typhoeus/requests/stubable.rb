module Typhoeus
  module Requests
    module Stubable
      def run
        if expectation = Expectation.find_by(self)
          @response = expectation.response
          execute_callbacks
        else
          super
        end
      end
    end
  end
end
