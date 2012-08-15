module Typhoeus
  module Hydras

    # This module handles stubbing on the hydra side.
    # It plays well with the block_connection configuration,
    # which raises when you make a request which is not stubbed.
    module Stubbable

      # Override queue in order to check for matching expecations.
      # When an expecation is found, super is not called. Instead a
      # canned response is assigned to the request.
      #
      # @example Queue the request.
      #   hydra.queue(request)
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
