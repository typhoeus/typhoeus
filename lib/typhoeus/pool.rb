require 'thread'

module Typhoeus

  # The easy pool stores already initialized
  # easy handles for future use. This is useful
  # because creating them is expensive.
  #
  # @api private
  module Pool
    @mutex = Mutex.new

    # Releases easy into the pool. The easy handle is
    # reset before it gets back in.
    #
    # @example Release easy.
    #   Typhoeus::Pool.release(easy)
    def self.release(easy)
      easy.reset
      @mutex.synchronize { easies << easy }
    end

    # Return an easy from the pool.
    #
    # @example Return easy.
    #   Typhoeus::Pool.get
    #
    # @return [ Ethon::Easy ] The easy.
    def self.get
      @mutex.synchronize { easies.pop } || Ethon::Easy.new
    end

    # Clear the pool
    def self.clear
      @mutex.synchronize { easies.clear }
    end

    # Use yielded easy, will be released automatically afterwards.
    #
    # @example Use easy.
    #   Typhoeus::Pool.with_easy do |easy|
    #     # use easy
    #   end
    def self.with_easy(&block)
      easy = get
      yield easy
    ensure
      release(easy) if easy
    end

    private

    def self.easies
      @easies ||= []
    end
  end
end
