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
      reset_after_fork

      if cleanup
        easy.cleanup
        return
      end

      clear_cookies(easy)
      easy.reset

      discarded = nil
      @mutex.synchronize do
        if max_size && easies.length >= max_size
          discarded = easy
        else
          easies << easy
        end
      end
      discarded.cleanup if discarded
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
      reset_after_fork
      @mutex.synchronize { easies.pop } || Ethon::Easy.new
    end

    # Clear the pool
    def self.clear
      reset_after_fork
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

    # Drop state inherited from a parent process. The previous mutex may have
    # been locked by a thread that does not exist after the fork, so it is
    # replaced without locking it to avoid a deadlock.
    def self.reset_after_fork
      return if @pid == Process.pid

      # Replace the lock before publishing the new pid so a thread that sees
      # the new pid cannot pick up the inherited lock.
      @mutex = Mutex.new
      @easies = []
      @pid = Process.pid
    end

    def self.max_size
      Typhoeus::Config.max_idle_easies if defined?(Typhoeus::Config)
    end

    def self.easies
      @easies ||= []
    end

    # Flush cookies to the configured jar and clear them from the handle.
    # libcurl builds without cookie support reject CURLOPT_COOKIELIST; that
    # must not prevent the handle from being recycled.
    def self.clear_cookies(easy)
      easy.cookielist = "flush"
      easy.cookielist = "all"
    rescue StandardError => e
      raise unless defined?(Ethon::Errors::UnsupportedOption) &&
        e.is_a?(Ethon::Errors::UnsupportedOption)
    end
  end
end
