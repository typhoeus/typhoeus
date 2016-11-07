module Typhoeus
  # This module provides a simple way to cache HTTP responses using Dalli.
  class DalliCache
    # @example Set Dalli as the Typhoeus cache backend
    #   Typhoeus::Config.cache = Typhoeus::DalliCache.new
    #
    # @param [ Dalli::Client ] client
    #   A connection to the cache server. Defaults to `Dalli::Client.new`
    # @param [ Integer ] default_ttl
    #   The default TTL of cached responses in seconds, for requests which do not set a cache_ttl.
    def initialize(client = Dalli::Client.new, default_ttl: nil)
      @client = client
      @default_ttl = default_ttl
    end

    def get(request)
      @client.get(request.cache_key)
    end

    def set(request, response)
      @client.set(request.cache_key, response, request.cache_ttl || @default_ttl)
    end
  end
end
