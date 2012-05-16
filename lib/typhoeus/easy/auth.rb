module Typhoeus
  module EasyFu
    module Auth
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def auth_types
          @auth_types ||= Curl::Auth.to_hash
        end

        def auth_type_for(auth_type)
          auth_types[auth_type] || auth_type
        end
      end

      def auth=(authinfo)
        set_option(:userpwd, auth_credentials(authinfo))
        set_option(:httpauth, self.class.auth_type_for(authinfo[:method])) if authinfo[:method]
      end

      def auth_credentials(authinfo)
        "#{authinfo[:username]}:#{authinfo[:password]}"
      end
    end
  end
end
