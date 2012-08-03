module Typhoeus
  module Requests
    module Stubable
      def run
        if expectation = Expectation.find_by(self)
          @response = expectation.response
          complete
        else
          super
        end
      end
    end
  end
end
