# frozen_string_literal: true

module Typhoeus
  class Request
    module Cacheable
      def response=(response)
        if cacheable? && cacheable_response?(response)
          cache.set(self, response)
        end
        super
      end

      def cacheable?
        cache
      end

      def run
        if response = cached_response
          finish_cached_response(response)
        else
          super
        end
      end

      # Finish a response that came from the cache and deliver it through the
      # same callbacks a stubbed response uses.
      #
      # @param [ Typhoeus::Response ] response The cached response.
      #
      # @return [ Typhoeus::Response ] The response.
      #
      # @api private
      def finish_cached_response(response)
        copy = response.dup
        copy.cached = true
        copy.request = self
        execute_headers_callbacks(copy)
        on_body.each { |callback| callback.call(copy.body, copy) }
        finish(copy)
      end

      def cached_response
        cacheable? && cache.get(self)
      end

      def cache_ttl
        options[:cache_ttl]
      end

      private

      def cache
        return nil if options[:cache] === false
        options[:cache] || Typhoeus::Config.cache
      end

      # A streaming response has no buffered body, and a transport failure or a
      # stub is not a representation of the resource.
      #
      # @param [ Typhoeus::Response ] response The response to cache.
      #
      # @return [ Boolean ] Whether the response should be cached.
      def cacheable_response?(response)
        !response.cached? &&
          !streaming? &&
          !response.mock? &&
          (response.return_code.nil? || response.return_code == :ok)
      end
    end
  end
end
