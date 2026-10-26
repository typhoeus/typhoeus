# frozen_string_literal: true

module Typhoeus
  class Hydra
    module Cacheable
      def add(request)
        if request.cacheable? && response = request.cached_response
          response.cached = true
          request.finish(response)
          dequeue_many
        else
          super
        end
      end
    end
  end
end
