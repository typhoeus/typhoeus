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
      rescue Exception => error
        begin
          cleanup_after_error
          reset_multi if multi_handle_unusable?(error)
        rescue StandardError
          # Preserve the original error.
        end
        raise
      end

      private

      # Clean up the easies and requests a failed run left behind.
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
            Typhoeus::Pool.release(easy, :cleanup => true)
          rescue StandardError
            # Keep cleaning up the remaining handles.
          end
        end
        queued_requests.clear
      end

      # A fatal multi_perform error leaves the native multi handle in an
      # unknown state. Replace it so the hydra can run requests again.
      #
      # @return [ void ]
      def reset_multi
        begin
          multi.cleanup if multi.respond_to?(:cleanup)
        rescue StandardError
          # Freeing the old handle is best effort; it is unusable anyway.
        end
        @multi = build_multi
      end

      # Ethon 0.19 raises MultiPerform when libcurl reports a fatal error from
      # curl_multi_perform. Earlier versions do not have the class.
      #
      # @param [ Exception ] error The error raised by the run.
      #
      # @return [ Boolean ] Whether the multi handle has to be replaced.
      def multi_handle_unusable?(error)
        defined?(Ethon::Errors::MultiPerform) &&
          error.is_a?(Ethon::Errors::MultiPerform)
      end
    end
  end
end
