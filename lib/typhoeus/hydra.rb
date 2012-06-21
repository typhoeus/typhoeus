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
        multi.add(get_easy_object(request))
      else
        queued_requests << request
      end
    end

    def run
      multi.perform
    end

    private

    def get_easy_object(request)
      easy = easy_pool.pop || Ethon::Easy.new
      agent_options = request.options.dup

      if agent_options[:headers]
        agent_options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(agent_options[:headers])
      else
        agent_options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end

      easy.http_request(request.url, request.action || :get, agent_options)
      easy.prepare
      set_callback(easy, request)
      easy
    end

    def set_callback(easy, request)
      easy.on_complete do |easy|
        request.response = Response.new(easy.to_hash)
        easy.reset
        easy_pool.push easy
        queue(queued_requests.shift) unless queued_requests.empty?
        request.complete
      end
    end
  end
end
