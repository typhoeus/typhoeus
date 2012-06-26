module Typhoeus
  module Requests

    # This module contains everything what is necessary
    # to make a single request.
    module Operations

      # :nodoc:
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods # :nodoc:

        # Shortcut to perform a single request.
        #
        # @example Perform request.
        #   Request.run("www.example.com")
        #
        # @param [ String ] url The url to request.
        # @param [ Hash ] options The options hash.
        #
        # @return [ Response ] The response.
        def run(url, params = {})
          new(url, params).run
        end
      end

      # Run a request.
      #
      # @example Run a request.
      #  request.run
      #
      # @return [ Response ] The response.
      def run
        easy = Typhoeus.get_easy
        easy.http_request(url, options[:method] || :get, options)
        easy.prepare
        easy.perform
        @response = Response.new(easy.to_hash)
        Typhoeus.release_easy(easy)
        complete
        @response
      end
    end
  end
end
