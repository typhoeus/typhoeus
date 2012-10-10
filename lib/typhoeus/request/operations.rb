module Typhoeus
  class Request

    # This module contains everything what is necessary
    # to make a single request.
    module Operations

      # Run a request.
      #
      # @example Run a request.
      #  Typhoeus::Request.new("www.example.com").run
      #
      # @return [ Response ] The response.
      def run
        easy = Typhoeus.get_easy
        easy.http_request(
          url,
          options.fetch(:method, :get),
          options.reject{|k,_| k==:method}
        )
        easy.prepare
        easy.perform
        finish(Response.new(easy.to_hash))
        Typhoeus.release_easy(easy)
        response
      end

      # Sets a response, the request on the response
      # and executes the callbacks.
      #
      # @param [Typhoeus::Response] response The response.
      # @param [Boolean] bypass_memoization Wether to bypass
      #   memoization or not. Decides how the response is set.
      #
      # @return [Typhoeus::Response] The response.
      def finish(response, bypass_memoization = nil)
        if bypass_memoization
          @response = response
        else
          self.response = response
        end
        self.response.request = self
        execute_callbacks
        response
      end
    end
  end
end
