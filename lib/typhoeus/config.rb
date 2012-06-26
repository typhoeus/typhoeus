module Typhoeus

  # The Typhoeus configuration used to set global
  # options. Available options:
  # * verbose
  # * memoize.
  module Config
    extend self
    attr_accessor :verbose, :memoize
  end
end
