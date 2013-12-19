module Typhoeus
  class Request

    # This module contains the logic for the response callbacks.
    # The on_complete callback is the only one at the moment.
    #
    # You can set multiple callbacks, which are then executed
    # in the same order.
    #
    #   request.on_complete { |response| p 1 }
    #   request.on_complete { |response| p 2 }
    #   request.execute_callbacks
    #   #=> 1
    #   #=> 2
    #
    # You can clear the callbacks:
    #
    #   request.on_complete { |response| p 1 }
    #   request.on_complete { |response| p 2 }
    #   request.on_complete.clear
    #   request.execute_callbacks
    #   #=> []
    #
    # @note If you're using the Hydra to execute multiple
    #   requests, then callbacks are delaying the
    #   request execution.
    module Callbacks

      module Types # :nodoc:
        # Set on_complete callback.
        #
        # @example Set on_complete.
        #   request.on_complete { |response| p "yay" }
        #
        # @param [ Block ] block The block to execute.
        #
        # @yield [ Typhoeus::Response ]
        #
        # @return [ Array<Block> ] All on_complete blocks.
        def on_complete(&block)
          @on_complete ||= []
          @on_complete << block if block_given?
          @on_complete
        end

        # Set on_success callback.
        #
        # @example Set on_success.
        #   request.on_success { |response| p "yay" }
        #
        # @param [ Block ] block The block to execute.
        #
        # @yield [ Typhoeus::Response ]
        #
        # @return [ Array<Block> ] All on_success blocks.
        def on_success(&block)
          @on_success ||= []
          @on_success << block if block_given?
          @on_success
        end

        # Set on_failure callback.
        #
        # @example Set on_failure.
        #   request.on_failure { |response| p "yay" }
        #
        # @param [ Block ] block The block to execute.
        #
        # @yield [ Typhoeus::Response ]
        #
        # @return [ Array<Block> ] All on_failure blocks.
        def on_failure(&block)
          @on_failure ||= []
          @on_failure << block if block_given?
          @on_failure
        end

        # Set on_headers callback.
        #
        # @example Set on_headers.
        #   request.on_headers { |response| p "yay" }
        #
        # @param [ Block ] block The block to execute.
        #
        # @yield [ Typhoeus::Response ]
        #
        # @return [ Array<Block> ] All on_headers blocks.
        def on_headers(&block)
          @on_headers ||= []
          @on_headers << block if block_given?
          @on_headers
        end
      end

      # Execute the headers callbacks and yields response.
      #
      # @example Execute callbacks.
      #   request.execute_headers_callbacks
      #
      # @return [ Array<Object> ] The results of the on_headers callbacks.
      #
      # @api private
      def execute_headers_callbacks(response)
        (Typhoeus.on_headers + on_headers).map do |callback|
          callback.call(response)
        end
      end

      # Execute necessary callback and yields response. This
      # include in every case on_complete, on_success if
      # successful and on_failure if not.
      #
      # @example Execute callbacks.
      #   request.execute_callbacks
      #
      # @return [ void ]
      #
      # @api private
      def execute_callbacks
        callbacks = Typhoeus.on_complete + on_complete

        if response && response.success?
          callbacks += Typhoeus.on_success + on_success
        elsif response
          callbacks += Typhoeus.on_failure + on_failure
        end

        callbacks.map do |callback|
          self.response.handled_response = callback.call(self.response)
        end
      end
    end
  end
end
