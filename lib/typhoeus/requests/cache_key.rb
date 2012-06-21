module Typhoeus
  module Requests
    module CacheKey
      def self.included(base)
        base.send(:attr_accessor, :cache_key_basis)
      end

      def cache_key
        Digest::SHA1.hexdigest(cache_key_basis || url)
      end
    end
  end
end
