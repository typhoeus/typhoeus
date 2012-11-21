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
        number_requests = 0
        loop do
          break if number_requests == max_concurrency || queued_requests.empty?
          number_requests += queued_requests.pop(max_concurrency).map do |request|
            add(request)
          end.size
        end
        multi.perform
      end
    end
  end
end
