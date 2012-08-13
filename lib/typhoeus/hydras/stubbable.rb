module Typhoeus
  module Hydras
    module Stubbable
      def queue(request)
        if expectation = Expectation.find_by(request)
          request.response = expectation.response
          request.response.mock = true
          request.execute_callbacks
          request.response
        else
          super
        end
      end
    end
  end
end
