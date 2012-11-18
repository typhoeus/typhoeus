module Typhoeus
  class Hydra

    # This is a Factory for easies to be used in the hydra.
    # Before an easy is ready to be added to a multi the
    # on_complete callback to be set.
    # This is done by this class.
    #
    # @api private
    class EasyFactory

      # Returns the request provided.
      #
      # @return [ Typhoeus::Request ]
      attr_reader :request

      # Returns the hydra provided.
      #
      # @return [ Typhoeus::Hydra ]
      attr_reader :hydra

      # Create an easy factory.
      #
      # @example Create easy factory.
      #   Typhoeus::Hydra::EasyFactory.new(request, hydra)
      #
      # @param [ Request ] request The request to build an easy for.
      # @param [ Hydra ] hydra The hydra to build an easy for.
      def initialize(request, hydra)
        @request = request
        @hydra = hydra
      end

      # Return the easy in question.
      #
      # @example Return easy.
      #   easy_factory.easy
      #
      # @return [ Ethon::Easy ] The easy.
      def easy
        @easy ||= hydra.get_easy
      end

      # Fabricated easy.
      #
      # @example Prepared easy.
      #   easy_factory.get
      #
      # @return [ Ethon::Easy ] The easy.
      def get
        easy.http_request(
          request.url,
          request.options.fetch(:method, :get),
          request.options.reject{|k,_| k==:method}
        )
        set_callback
        easy
      end

      private

      # Sets on_complete callback on easy in order to be able to
      # track progress.
      #
      # @example Set callback.
      #   easy_factory.set_callback
      #
      # @return [ Ethon::Easy ] The easy.
      def set_callback
        easy.on_complete do |easy|
          request.finish(Response.new(easy.to_hash))
          hydra.release_easy(easy)
          hydra.add(hydra.queued_requests.shift) unless hydra.queued_requests.empty?
        end
      end
    end
  end
end
