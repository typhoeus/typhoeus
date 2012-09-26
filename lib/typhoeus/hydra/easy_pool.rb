module Typhoeus
  class Hydra

    # The easy pool stores already initialized
    # easy handles for future use. This is useful
    # because creating them is quite expensive.
    #
    # @api private
    module EasyPool

      # Return the easy pool.
      #
      # @example Return easy pool.
      #   hydra.easy_pool
      #
      # @return [ Array<Ethon::Easy> ] The easy pool.
      def easy_pool
        @easy_pool ||= []
      end

      # Releases easy into pool. The easy handle is
      # resetted before it gets back in.
      #
      # @example Release easy.
      #   hydra.release_easy(easy)
      def release_easy(easy)
        easy.reset
        easy_pool << easy
      end

      # Return an easy from pool.
      #
      # @example Return easy.
      #   hydra.get_easy
      #
      # @return [ Ethon::Easy ] The easy.
      def get_easy
        easy_pool.pop || Ethon::Easy.new
      end
    end
  end
end
