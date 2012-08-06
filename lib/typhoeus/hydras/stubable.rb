module Typhoeus
  module Hydras
    module Stubable
      def queue(request)
        if expectation = Expectation.find_by(request)
          request.response = expectation.response
          request.execute_callbacks
        else
          super
        end
      end
    end
  end
end
