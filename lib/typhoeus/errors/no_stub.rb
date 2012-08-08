module Typhoeus
  module Errors

    # Raises when fake is turned on and making a
    # real request.
    class NoStub < TyphoeusError
      def initialize(request)
        super("No real requests allowed because fake is turned on and no stub found.")
      end
    end
  end
end
