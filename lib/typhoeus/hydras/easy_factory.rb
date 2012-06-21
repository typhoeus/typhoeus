module Typhoeus
  module Hydras
    class EasyFactory
      attr_reader :request, :hydra

      def initialize(request, hydra)
        @request = request
        @hydra = hydra
      end

      def easy
        @easy ||= (hydra.easy_pool.pop || Ethon::Easy.new)
      end

      def get
        agent_options = request.options.dup

        if agent_options[:headers]
          agent_options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(agent_options[:headers])
        else
          agent_options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
        end

        easy.http_request(request.url, request.action || :get, agent_options)
        easy.prepare
        set_callback
        easy
      end

      def set_callback
        easy.on_complete do |easy|
          request.response = Response.new(easy.to_hash)
          easy.reset
          hydra.easy_pool.push easy
          hydra.queue(hydra.queued_requests.shift) unless hydra.queued_requests.empty?
          request.complete
        end
      end
    end
  end
end
