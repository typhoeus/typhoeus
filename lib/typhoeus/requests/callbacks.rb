module Typhoeus
  module Requests
    module Callbacks
      def on_complete(&block)
        @on_complete = block
      end

      def complete
        @on_complete.call(self) if defined?(@on_complete)
      end
    end
  end
end
