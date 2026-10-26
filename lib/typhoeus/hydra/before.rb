# frozen_string_literal: true

module Typhoeus
  class Hydra

    # This module provides a way to hook into before
    # a request gets queued in hydra. This is very powerful
    # and you should be careful because when you accidently
    # return a falsy value the request won't be executed.
    #
    # @api private
    module Before

      # Overrride add in order to execute callbacks in
      # Typhoeus.before and request specific callbacks. Will
      # break and return when a callback returns nil, false or
      # a response. Calls super otherwise.
      #
      # @example Add the request.
      #   hydra.add(request)
      def add(request)
        (Typhoeus.before + request.before).each do |callback|
          value = callback.call(request)
          if value.is_a?(Response)
            unless request.response
              request.execute_headers_callbacks(value)
              request.on_body.each { |body_callback| body_callback.call(value.body, value) }
              request.finish(value)
            end
            dequeue_many
            return value
          elsif value.nil? || value == false
            dequeue_many
            return value
          end
        end
        super
      end
    end
  end
end
