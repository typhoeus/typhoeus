require 'typhoeus/hydras/easy_factory'

module Typhoeus

  # Hydra manages making parallel HTTP requests
  #
  class Hydra
    attr_reader :initial_pool_size, :queued_requests,
      :max_concurrency, :easy_pool, :multi

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
      @initial_pool_size = @options[:initial_pool_size] || 10
      @max_concurrency = @options[:max_concurrency] || 200
      @multi = Ethon::Multi.new
    end

    def abort
      queued_requests.clear
    end

    def queue(request)
      if multi.easy_handles.size < max_concurrency
        multi.add(Hydras::EasyFactory.new(request, self).get)
      else
        queued_requests << request
      end
    end

    def run
      multi.perform
    end
  end
end
