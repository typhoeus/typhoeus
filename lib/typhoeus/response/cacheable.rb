module Typhoeus
  class Response
    module Cacheable

      # Set the cache status, if we got response from cache
      # it will have cached? == true
      attr_writer :cached

      def cached?
        !!@cached
      end
    end
  end
end
