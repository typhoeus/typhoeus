# require 'typhoeus/hydra/callbacks'
# require 'typhoeus/hydra/connect_options'
# require 'typhoeus/hydra/stubbing'

module Typhoeus

  # Hydra manages making parallel HTTP requests
  #
  class Hydra
    # include ConnectOptions
    # include Stubbing
    # extend Callbacks

    def initialize(options = {})
      @options = options
    end

    def queued_requests
      @queued_requests ||= []
    end

    def initial_pool_size
      @initial_pool_size ||= (@options[:initial_pool_size] || 10)
    end

    def max_concurrency
      @max_concurrency ||= (@options[:max_concurrency] || 200)
    end

    def easy_pool
      @easy_pool ||= []
    end

    def self.hydra
      @hydra ||= new
    end

    def self.hydra=(val)
      @hydra = val
    end

    def abort
      queued_requests.clear
    end

    # def fire_and_forget
    #   @queued_requests.each {|r| queue(r, false)}
    #   @multi.fire_and_forget
    # end

    def queue(request)
      if multi.easy_handles.size < max_concurrency
        multi.add(get_easy_object(request))
      else
        queued_requests << request
      end
    end

    def multi
      @multi ||= Ethon::Multi.new
    end

    def run
      return if multi.easy_handles.empty?
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
      end
    end
  end
end
