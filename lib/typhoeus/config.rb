module Typhoeus

  # The Typhoeus configuration used to set global
  # options. Available options:
  # * fake: only stubbed requests are allowed
  # * verbose: show curls debug out
  # * memoize: memoize GET requests.
  module Config
    extend self
    attr_accessor :block_connection, :memoize, :verbose
  end
end
