# frozen_string_literal: true

require 'thread'

module Typhoeus

  # The easy pool stores already initialized
  # easy handles for future use. This is useful
  # because creating them is expensive.
  #
  # @api private
  module Pool
    @mutex = Mutex.new
    @pid = Process.pid

    # Releases easy into the pool. The easy handle is
    # reset before it gets back in.
    #
    # @example Release easy.
    #   Typhoeus::Pool.release(easy)
    #
    # @example Clean up instead of pooling.
    #   Typhoeus::Pool.release(easy, :cleanup => true)
    def self.release(easy, cleanup: false)
      if cleanup
        easy.cleanup
        return
      end

      if @pid != Process.pid
        @mutex.synchronize do
          @pid = Process.pid
          easies.clear
        end
      end

      easy.cookielist = "flush" # dump all known cookies to 'cookiejar'
      easy.cookielist = "all" # remove all cookies from memory for this handle
      easy.reset
      @mutex.synchronize { easies << easy }
    rescue StandardError => e
      # Ethon 0.19+ refuses to reset handles created before a fork.
      raise unless defined?(Ethon::Errors::ForkSafety) && e.is_a?(Ethon::Errors::ForkSafety)
    end

    # Return an easy from the pool.
    #
    # @example Return easy.
    #   Typhoeus::Pool.get
    #
    # @return [ Ethon::Easy ] The easy.
    def self.get
      @mutex.synchronize do
        if @pid == Process.pid
          easies.pop
        else
          # Process has forked. Clear all easies to avoid sockets being
          # shared between processes.
          @pid = Process.pid
          easies.clear
          nil
        end
      end || Ethon::Easy.new
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
