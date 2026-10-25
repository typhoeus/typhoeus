# frozen_string_literal: true

module Typhoeus
  class Hydra

    # This module handles the request adding on
    # hydra.
    #
    # @api private
    module Addable

      # Adds request to multi.
      #
      # @example Add request.
      #   hydra.add(request)
      #
      # @param [ Typhoeus::Request ] request to add.
      #
      # @return [ void ]
      def add(request)
        easy_factory = EasyFactory.new(request, self)
        easy = easy_factory.get
        begin
          multi.add(easy)
        rescue Exception
          Typhoeus::Pool.release(easy) unless easy_factory.released?
          raise
        end
      end
    end
  end
end
