module Typhoeus
  class Hydra
    class NetConnectNotAllowedError < StandardError; end

    module ConnectOptions
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This method checks to see if we should raise an error on
      # a request.
      #
      # @raises NetConnectNotAllowedError
      def check_allow_net_connect!
        unless Typhoeus::Hydra.allow_net_connect?
          raise NetConnectNotAllowedError, "Real HTTP requests are not allowed."
        end
      end
      private :check_allow_net_connect!

      module ClassMethods
        def self.extended(base)
          class << base
            attr_accessor :allow_net_connect
          end
          base.allow_net_connect = true
        end

        # Returns whether we allow external HTTP connections.
        # Useful for mocking/tests.
        #
        # @return [boolean] true/false
        def allow_net_connect?
          allow_net_connect
        end
      end
    end
  end
end
