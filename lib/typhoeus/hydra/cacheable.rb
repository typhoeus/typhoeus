module Typhoeus
  class Hydra
    module Cacheable
      def add(request)
        if request.cacheable? && response = Typhoeus::Config.cache.get(request)
          request.finish(response)
          dequeue
        else
          super
        end
      end
    end
  end
end
