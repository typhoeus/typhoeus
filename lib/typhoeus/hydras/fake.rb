module Typhoeus
  module Hydras

    # This module handles the fake request mode on
    # the hydra side, where only stubbed requests
    # are allowed.
    # Fake needs to be turned on:
    #   Typhoeus.configure do |config|
    #     config.fake = true
    #   end
    #
    # When trying to do real requests a NoStub error
    # is raised.
    module Fake

      # Overrides queue in order to check before if fake
      # is turned on. If thats the case a NoStub error is
      # raised.
      #
      # @example Queue the request.
      #   hydra.queue(request)
      #
      # @param [ Request ] request The request to enqueue.
      def queue(request)
        if Typhoeus::Config.fake
          raise Typhoeus::Errors::NoStub.new(request)
        else
          super
        end
      end
    end
  end
end
