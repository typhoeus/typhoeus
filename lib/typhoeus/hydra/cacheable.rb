module Typhoeus
  class Hydra
    module Cacheable
      def add(request)
        if request.cacheable? && response = Typhoeus::Config.cache.get(request.hash)
          response.cached = true
          request.finish(response)
          dequeue
        else
          super
        end
      end
    end
  end
end
