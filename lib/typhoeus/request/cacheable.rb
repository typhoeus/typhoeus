module Typhoeus
  class Request
    module Cacheable
      def response=(response)
        Typhoeus::Config.cache.set(self, response) if cacheable?
        super
      end

      def cacheable?
        Typhoeus::Config.cache
      end
    end
  end
end
