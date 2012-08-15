module Typhoeus

  # The Typhoeus configuration used to set global
  # options. Available options:
  # * block_connection: only stubbed requests are
  #   allowed, raises NoStub error when trying to
  #   do a real request.
  # * verbose: show curls debug out
  # * memoize: memoize GET requests.
  module Config
    extend self
    attr_accessor :block_connection, :memoize, :verbose
  end
end
