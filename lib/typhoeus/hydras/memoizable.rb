module Typhoeus
  module Hydras

    # This module handles the GET request memoization
    # on the hydra side. Memoization needs to be turned
    # on:
    #   Typhoeus.configure do |config|
    #     config.memoize = true
    #   end
    module Memoizable

      # Return the memory.
      #
      # @example Return the memory.
      #   hydra.memory
      #
      # @return [ Hash ] The memory.
      def memory
        @memory ||= {}
      end

      # Overrides queue in order to check before if request
      # is memoizable and already in memory. If thats the case,
      # super is not called, instead the response is set and
      # the on_complete callback called.
      #
      # @example Queue the request.
      #   hydra.queue(request)
      #
      # @param [ Request ] request The request to enqueue.
      #
      # @return [ Request ] The queued request.
      def queue(request)
        if request.memoizable? && memory.has_key?(request)
          request.instance_variable_set(:@response, memory[request])
          request.execute_callbacks
        else
          super
        end
      end

      # Overrides run to make sure the memory is cleared after
      # each run.
      #
      # @example Run hydra.
      #   hydra.run
      def run
        super
        memory.clear
      end
    end
  end
end
