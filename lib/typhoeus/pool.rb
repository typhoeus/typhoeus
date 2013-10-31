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

    # Releases easy into the pool. The easy handle is
    # reset before it gets back in.
    #
    # @example Release easy.
    #   hydra.release_easy(easy)
    def release(easy)
      easy.reset
      @mutex.synchronize { easies << easy }
    end

    # Return an easy from the pool.
    #
    # @example Return easy.
    #   hydra.get_easy
    #
    # @return [ Ethon::Easy ] The easy.
    def get
      @mutex.synchronize { easies.pop } || Ethon::Easy.new
    end

    def clear
      @mutex.synchronize { easies.clear }
    end

    def with_easy(&block)
      easy = get
      yield easy
    ensure
      release(easy) if easy
    end

    private

    # Return the easy pool.
    #
    # @example Return easy pool.
    #   hydra.easy_pool
    #
    # @return [ Array<Ethon::Easy> ] The easy pool.
    def easies
      @easies ||= []
    end
  end
end
