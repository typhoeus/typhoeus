module Typhoeus::Pooling

  # The easy pool stores already initialized
  # easy handles for future use. This is useful
  # because creating them is expensive.
  #
  # @api private
  module Easies
    @pool = Pool.new

    # Releases easy into the pool. The easy handle is
    # reset before it gets back in.
    #
    # @example Release easy.
    #   Typhoeus::Pooling::Easies.release(easy)
    def self.release(easy)
      easy.cookielist = "flush" # dump all known cookies to 'cookiejar'
      easy.cookielist = "all" # remove all cookies from memory for this handle
      easy.reset
      @pool.release(easy)
    end

    # Return an easy from the pool.
    #
    # @example Return easy.
    #   Typhoeus::Pooling::Easies.get
    #
    # @return [ Ethon::Easy ] The easy.
    def self.get
      @pool.get || Ethon::Easy.new
    end

    # Clear the pool
    def self.clear
      @pool.clear
    end

    # Use yielded easy, will be released automatically afterwards.
    #
    # @example Use easy.
    #   Typhoeus::Pooling::Easies.with_easy do |easy|
    #     # use easy
    #   end
    def self.with_easy(&block)
      easy = get
      yield easy
    ensure
      release(easy) if easy
    end
  end
end
