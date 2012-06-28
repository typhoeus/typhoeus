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
        @on_complete ||= []
        @on_complete << block if block_given?
        @on_complete
      end

      # Execute on_complete callbacks.
      #
      # @example Execute on_completes.
      #   request.complete
      def complete
        if defined?(@on_complete)
          @on_complete.map{ |callback| callback.call(self) }
        end
      end
    end
  end
end
