module Typhoeus
  module Requests
    module Operations
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def run(url, params = {})
          r = new(url, params)
          r.run
        end
      end

      def run
        easy = Typhoeus.get_easy_object
        easy.http_request(url, options[:method] || :get, options)
        easy.prepare
        easy.perform
        @response = Response.new(easy.to_hash)
        Typhoeus.release_easy_object(easy)
        complete
        @response
      end
    end
  end
end
