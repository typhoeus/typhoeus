module Typhoeus
  class Hydra

    # This module provides a way to hook into before
    # a request gets queued. This is very powerful and
    # should be done correctly.
    module Before

      # Overrride queue in order to execute callbacks in
      # Typhoeus.before. Will break and return when a
      # callback returns nil or false. Calls super
      # otherwise.
      #
      # @example Queue the request.
      #   hydra.queue(request)
      def queue(request)
        Typhoeus.before.each do |callback|
          value = callback.call(request)
          return value unless value
        end
        super
      end
    end
  end
end
