# frozen_string_literal: true

module Typhoeus
  class Request

    # This module provides a way to hook into before
    # a request runs. This is very powerful
    # and you should be careful because when you
    # accidentally return a falsy value the request won't be executed.
    #
    # @api private
    module Before

      # Add a callback that runs before the request.
      #
      # @example Add a callback.
      #   request.before { |request| request.options[:timeout] = 5 }
      #
      # @param [ Proc ] block The callback to run.
      #
      # @yield [ Typhoeus::Request ]
      #
      # @return [ Array<Proc> ] The callbacks.
      def before(&block)
        @before ||= []
        @before << block if block_given?
        @before
      end

      # Overrride run in order to execute callbacks in
      # Typhoeus.before and request specific callbacks. Will
      # break and return when a callback returns nil or false.
      # A callback that returns a Response short-circuits the
      # request and that response is returned. Calls super otherwise.
      #
      # @example Run the request.
      #   request.run
      def run
        (Typhoeus.before + before).each do |callback|
          value = callback.call(self)
          if value.nil? || value == false || value.is_a?(Response)
            return value if value.is_a?(Response)
            return response
          end
        end
        super
      end
    end
  end
end
