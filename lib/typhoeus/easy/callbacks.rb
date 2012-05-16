module Typhoeus
  module EasyFu
    module Callbacks
      # gets called when finished and response code is not 2xx,
      # or curl returns an error code.
      def success
        @success.call(self) if @success
      end

      def on_success(&block)
        @success = block
      end

      def on_success=(block)
        @success = block
      end

      # gets called when finished and response code is 300-599
      # or curl returns an error code
      def failure
        @failure.call(self) if @failure
      end

      def on_failure(&block)
        @failure = block
      end

      def on_failure=(block)
        @failure = block
      end
    end
  end
end
