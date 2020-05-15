module Typhoeus::Pooling

  # The multi pool stores already initialized
  # multi handles for future use. This is useful
  # because creating them is expensive.
  #
  # @api private
  module Multis
    @pool = Pool.new

    # Releases multi into the pool.
    # Cleans up any attached easy handles.
    #
    # @example
    #   Typhoeus::Pooling::Multis.release(multi)
    #
    # @param [Ethon::Multi] multi
    def self.release(multi)
      # Clean up any handles that didn't complete.
      multi.easy_handles.dup.each do |easy|
        multi.delete(easy)
        Easies.release(easy)
      end
      @pool.release(multi)
    end

    # Return a multi from the pool.
    #
    # @example
    #   multi = Typhoeus::Pooling::Multis.get
    #
    # @return [Ethon::Multi]
    def self.get
      @pool.get || Ethon::Multi.new
    end

    # Clear the pool
    def self.clear
      @pool.clear
    end
  end
end
