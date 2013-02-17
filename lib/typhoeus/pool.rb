require 'thread'

module Typhoeus

  # The easy pool stores already initialized
  # easy handles for future use. This is useful
  # because creating them is quite expensive.
  #
  # @api private
  module Pool
    extend self

    @mutex = Mutex.new

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
      @mutex.synchronize do
        easy.reset
        easies << easy
      end
    end

    # Return an easy from pool.
    #
    # @example Return easy.
    #   hydra.get_easy
    #
    # @return [ Ethon::Easy ] The easy.
    def get
      @mutex.synchronize do
        easies.pop || Ethon::Easy.new
      end
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
