module Typhoeus
  module EasyFu
    module Auth
      def auth=(authinfo)
        set_option(:userpwd, auth_credentials(authinfo))
        set_option(:httpauth, Typhoeus::Easy::AUTH_TYPES[authinfo[:method]]) if authinfo[:method]
      end

      def auth_credentials(authinfo)
        "#{authinfo[:username]}:#{authinfo[:password]}"
      end
    end
  end
end
