require 'typhoeus/hydras/easy_factory'
require 'typhoeus/hydras/easy_pool'
require 'typhoeus/hydras/fake'
require 'typhoeus/hydras/memoizable'
require 'typhoeus/hydras/queueable'
require 'typhoeus/hydras/runnable'
require 'typhoeus/hydras/stubable'

module Typhoeus

  # Hydra manages making parallel HTTP requests. This
  # is achieved by using libcurls multi interface:
  # http://curl.haxx.se/libcurl/c/libcurl-multi.html
  # The benefits are that you don't have to worry running
  # the requests by yourself.
  class Hydra
    include Hydras::EasyPool
    include Hydras::Queueable
    include Hydras::Runnable
    include Hydras::Memoizable
    include Hydras::Fake
    include Hydras::Stubable

    attr_reader :max_concurrency, :multi

    # Create a new hydra.
    #
    # @example Create a hydra.
    #   Typhoeus::Hydra.new
    #
    # @param [ Hash ] options The options hash.
    #
    # @option options :max_concurrency [ Integer ] Number
    #  of max concurrent connections to create. Default is
    #  200.
    def initialize(options = {})
      @options = options
      @max_concurrency = @options.fetch(:max_concurrency, 200)
      @multi = Ethon::Multi.new
    end
  end
end
