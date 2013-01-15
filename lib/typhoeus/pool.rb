module Typhoeus

  # The easy pool stores already initialized
  # easy handles for future use. This is useful
  # because creating them is quite expensive.
  #
  # @api private
  module Pool
    extend self

    # Return the easy pool.
    #
    # @example Return easy pool.
    #   hydra.easy_pool
    #
    # @return [ Array<Ethon::Easy> ] The easy pool.
    def easies
      @easies ||= []
    end

    # Releases easy into pool. The easy handle is
    # resetted before it gets back in.
    #
    # @example Release easy.
    #   hydra.release_easy(easy)
    def release(easy)
      easy.reset
      easies << easy
    end

    # Return an easy from pool.
    #
    # @example Return easy.
    #   hydra.get_easy
    #
    # @return [ Ethon::Easy ] The easy.
    def get
      easies.pop || Ethon::Easy.new
    end

    def clear
      easies.clear
    end

    def with_easy(&block)
      easy = get
      yield easy
      release easy
    end
  end
end
