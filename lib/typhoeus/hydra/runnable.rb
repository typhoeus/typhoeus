# frozen_string_literal: true

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
      rescue Exception
        begin
          cleanup_after_error
        rescue StandardError
          # Preserve the original request error.
        end
        raise
      end

      private

      # Remove and release all easy handles left in the multi after a failed run.
      #
      # @return [ void ]
      def cleanup_after_error
        multi.easy_handles.dup.each do |easy|
          begin
            multi.delete(easy)
          rescue StandardError
            # The handle may already be unusable.
          end
          begin
            Typhoeus::Pool.release(easy)
          rescue StandardError
            # Keep cleaning up the remaining handles.
          end
        end
        queued_requests.clear
      end
    end
  end
end
