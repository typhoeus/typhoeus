module Typhoeus
  class Request

    # This module provides a way to hook into before
    # a request runs. This is very powerful
    # and you should be careful because when you accidently
    # return a falsy value the request won't be executed.
    #
    # @api private
    module Before
      # Set before callback.
      #
      # @example Set before.
      #   request.before { |request| p "yay" }
      #
      # @param [ Block ] block The block to execute.
      #
      # @yield [ Typhoeus::Request ]
      #
      # @return [ Array<Block> ] All before blocks.
      def before(&block)
        @before ||= []
        @before << block if block_given?
        @before
      end

      # Overrride run in order to execute callbacks in
      # Typhoeus.before. Will break and return when a
      # callback returns nil or false. Calls super
      # otherwise.
      #
      # @example Run the request.
      #   request.run
      def run
        callbacks = Typhoeus.before + before
        callbacks.each do |callback|
          value = callback.call(self)
          if value.nil? || value == false || value.is_a?(Response)
            return response
          end
        end
        super
      end
    end
  end
end
