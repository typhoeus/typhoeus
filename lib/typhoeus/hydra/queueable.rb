module Typhoeus
  class Hydra

    # This module handles the request queueing on
    # hydra.
    #
    # @api private
    module Queueable

      # Return the queued requests.
      #
      # @example Return queued requests.
      #  hydra.queued_requests
      #
      # @return [ Array<Typhoeus::Request> ] The queued requests.
      def queued_requests
        @queued_requests ||= []
      end

      # Abort the current hydra run as good as
      # possible. This means that it only
      # clears the queued requests and can't do
      # anything about already running requests.
      #
      # @example Abort hydra.
      #  hydra.abort
      def abort
        queued_requests.clear
      end

      # Enqueues a request in order to be performed
      # by the hydra. This can even be done while
      # the hydra is running. Also sets hydra on
      # request.
      #
      # @example Queue request.
      #  hydra.queue(request)
      def queue(request)
        request.hydra = self
        queued_requests << request
      end
    end
  end
end
