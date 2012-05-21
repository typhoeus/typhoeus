module Typhoeus
  module EasyFu
    module Proxy
      def proxy=(proxy)
        set_option(:proxy, proxy[:server])
        set_option(:proxytype, Typhoeus::Easy::PROXY_TYPES[proxy[:type]]) if proxy[:type]
      end

      def proxy_auth=(authinfo)
        set_option(:proxyuserpwd, proxy_credentials(authinfo))
        set_option(:proxyauth, Typhoeus::Easy::PROXY_TYPES[proxy[:type]]) if authinfo[:method]
      end

      def proxy_credentials(authinfo)
        "#{authinfo[:username]}:#{authinfo[:password]}"
      end
    end
  end
end

