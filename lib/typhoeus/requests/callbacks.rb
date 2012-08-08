module Typhoeus
  module Requests

    # This module contains the logic for the response callbacks.
    # The on_complete callback is the only one at the moment.
    #
    # You can set multiple callbacks, which are then executed
    # in the same order.
    #
    #   request.on_complete { p 1 }
    #   request.on_complete { p 2 }
    #   request.complete
    #   #=> 1
    #   #=> 2
    #
    # You can clear the callbacks:
    #
    #   request.on_complete { p 1 }
    #   request.on_complete { p 2 }
    #   request.on_complete.clear
    #   request.on_complete
    #   #=> []
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

      # Execute on_complete callbacks and yields
      # response.
      #
      # @example Execute on_completes.
      #   request.complete
      def complete
        (Typhoeus.on_complete + on_complete).map{ |callback| callback.call(self.response) }
      end

      def on_success(&block)
        @on_success ||= []
        @on_success << block if block_given?
        @on_success
      end

      def success
        (Typhoeus.on_success + on_success).map{ |callback| callback.call(self.response) }
      end

      def on_failure(&block)
        @on_failure ||= []
        @on_failure << block if block_given?
        @on_failure
      end

      def failure
        (Typhoeus.on_failure + on_failure).map{ |callback| callback.call(self.response) }
      end

      def execute_callbacks
        complete
        if response.try(:success?)
          success
        elsif response
          failure
        end
      end
    end
  end
end
