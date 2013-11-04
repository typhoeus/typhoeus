module Typhoeus
  class Request
    module Cacheable
      def response=(response)
        Typhoeus::Config.cache.set(self, response) if cacheable? && !response.cached?
        super
      end

      def cacheable?
        Typhoeus::Config.cache
      end

      def run
        if cacheable? && response = Typhoeus::Config.cache.get(self)
          response.cached = true
          finish(response)
        else
          super
        end
      end

      def cache_ttl
        options[:cache_ttl]
      end
    end
  end
end
