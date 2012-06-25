require 'typhoeus/hydras/easy_factory'
require 'typhoeus/hydras/memoizable'
require 'typhoeus/hydras/queueable'

module Typhoeus

  # Hydra manages making parallel HTTP requests
  #
  class Hydra
    include Hydras::Queueable
    include Hydras::Memoizable

    attr_reader :queued_requests, :max_concurrency, :easy_pool, :multi

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
      @easy_pool = []
      @max_concurrency = @options[:max_concurrency] || 200
      @multi = Ethon::Multi.new
    end

    def run
      multi.perform
    end
  end
end
