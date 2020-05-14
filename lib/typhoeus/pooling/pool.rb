require 'thread'

module Typhoeus::Pooling

  # A pool can store initialized networking resources for future use.
  # Handles threaded access and process forking.
  #
  # @api private
  class Pool

    attr_reader(:resources)

    # Create a new pool.
    #
    # @example
    #   pool = Typhoeus::Pooling::Pool.new
    def initialize
      @resources = []
      @mutex = Mutex.new
      @pid = Process.pid
    end

    # Releases a resource into the pool.
    #
    # @example
    #   pool.release(resource)
    #
    # @param [Object] resource
    def release(resource)
      @mutex.synchronize { @resources << resource }
    end

    # Get a resource from the pool, if available.
    #
    # @example
    #   resource = pool.get || Object.new
    #
    # @return [Object, nil]
    def get
      @mutex.synchronize do
        if @pid == Process.pid
          @resources.pop
        else
          # Process has forked. Clear resources to avoid sockets being
          # shared between processes.
          @pid = Process.pid
          @resources.clear
          nil
        end
      end
    end

    # Clear the pool.
    #
    # @example
    #   pool.clear
    def clear
      @mutex.synchronize { @resources.clear }
    end
  end
end
