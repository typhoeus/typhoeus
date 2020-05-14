module Typhoeus
  class Hydra

    # This module contains logic to run a hydra.
    module Runnable

      # Start the hydra run.
      #
      # @example Start hydra run.
      #   hydra.run
      #
      # @return [ Symbol ] Return value from multi.perform.
      def run
        dequeue_many
        multi.perform

        # Reset multi (releases it for reuse).
        self.multi = nil
      end
    end
  end
end
