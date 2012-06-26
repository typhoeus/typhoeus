require 'typhoeus/hydras/easy_pool'
require 'typhoeus/hydras/easy_factory'
require 'typhoeus/hydras/memoizable'
require 'typhoeus/hydras/queueable'
require 'typhoeus/hydras/runnable'

module Typhoeus

  # Hydra manages making parallel HTTP requests
  #
  class Hydra
    include Hydras::EasyPool
    include Hydras::Queueable
    include Hydras::Runnable
    include Hydras::Memoizable

    attr_reader :queued_requests, :max_concurrency, :multi

    class << self
      def hydra
        @hydra ||= new
      end

      def hydra=(val)
        @hydra = val
      end
    end

    def initialize(options = {})
      @options = options
      @queued_requests = []
      @max_concurrency = @options[:max_concurrency] || 200
      @multi = Ethon::Multi.new
    end
  end
end
