# frozen_string_literal: true

module Typhoeus
  class Hydra

    # This module handles the GET request memoization
    # on the hydra side. Memoization needs to be
    # turned on:
    #   Typhoeus.configure do |config|
    #     config.memoize = true
    #   end
    #
    # @api private
    module Memoizable

      # Return the memory.
      #
      # @example Get memory.
      #   hydra.memory
      #
      # @return [ Hash ] The memory.
      def memory
        @memory ||= {}
      end

      # Requests that are waiting for an identical request to finish.
      #
      # @return [ Hash ]
      #
      # @api private
      def pending
        @pending ||= {}
      end

      # Add a request. Memoized requests that are already completed are
      # answered from memory. Requests that are still in flight are attached
      # to the pending request so they share its response.
      #
      # @param [ Typhoeus::Request ] request
      #
      # @return [ Object ]
      def add(request)
        if request.memoizable?
          if memory.key?(request)
            response = memory[request]
            request.finish(response, true)
            dequeue_many
          elsif pending.key?(request)
            pending[request] << request
          else
            pending[request] = []
            request.on_complete { |response| finish_pending(request, response) }
            begin
              super
            rescue Exception
              pending.delete(request)
              raise
            end
          end
        else
          super
        end
      end

      # Run the hydra and clear the memoization state afterwards.
      #
      # @example Run hydra.
      #   hydra.run
      def run
        super
      ensure
        memory.clear
        pending.clear
      end

      private

      # Finish all requests that waited for the given request.
      #
      # @param [ Typhoeus::Request ] request
      # @param [ Typhoeus::Response ] response
      #
      # @return [ void ]
      def finish_pending(request, response)
        requests = pending.delete(request)
        return unless requests

        requests.each { |pending_request| pending_request.finish(response, true) }
      end
    end
  end
end
