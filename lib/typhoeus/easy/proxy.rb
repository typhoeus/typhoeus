module Typhoeus
  module EasyFu
    module Proxy
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def proxy_types
          @proxy_types ||= Curl::Proxy.to_hash
        end

        def proxy_type_for(proxy_type)
          proxy_types[proxy_type] || proxy_type
        end
      end

      def proxy=(proxy)
        set_option(:proxy, proxy[:server])
        set_option(:proxytype, proxy_type_for(proxy[:type])) if proxy[:type]
      end

      def proxy_auth=(authinfo)
        set_option(:proxyuserpwd, proxy_credentials(authinfo))
        # set_option(:proxyauth, AUTH_TYPES.key?(authinfo[:method]) ? AUTH_TYPES[authinfo[:method]] : authinfo[:method]) if authinfo[:method]
        set_option(:proxyauth, self.class.auth_type_for(authinfo[:method])) if authinfo[:method]
      end

      def proxy_credentials(authinfo)
        "#{authinfo[:username]}:#{authinfo[:password]}"
      end
    end
  end
end

