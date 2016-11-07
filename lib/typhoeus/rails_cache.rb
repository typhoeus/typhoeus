module Typhoeus
  # This module provides a simple way to cache HTTP responses in using the Rails cache.
  class RailsCache
    # @example Use the Rails cache setup to cache Typhoeus responses.
    #   Typhoeus::Config.cache = Typhoeus::RailsCache.new
    #
    # @param [ ActiveSupport::Cache::Store ] cache
    #   A Rails cache backend. Defaults to Rails.cache.
    # @param [ Integer ] default_ttl
    #   The default TTL of cached responses in seconds, for requests which do not set a cache_ttl.
    def initialize(cache = Rails.cache, default_ttl: nil)
      @cache = cache
      @default_ttl = default_ttl
    end

    def get(request)
      @cache.read(request)
    end

    def set(request, response)
      @cache.write(request, response, expires_in: request.cache_ttl || @default_ttl)
    end
  end
end
