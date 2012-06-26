module Typhoeus
  module Requests

    # This module contains logic about the available
    # callbacks on requests. Its only on_complete at
    # the moment.
    module Callbacks

      # Set on_complete callback.
      #
      # @example Set on_complete.
      #   request.on_complete { p "yay" }
      #
      # @param [ Block ] block The block to execute.
      def on_complete(&block)
        @on_complete = block
      end

      # Execute on_complete callback.
      #
      # @example Execute on_complete.
      #   request.complete
      def complete
        @on_complete.call(self) if defined?(@on_complete)
      end
    end
  end
end
