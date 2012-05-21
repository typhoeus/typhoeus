module Typhoeus
  module EasyFu
    module SSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def valid_ssl_version(version)
          Typhoeus::Easy::SSL_VERSIONS.key?(version.to_sym)
        end
      end

      def ssl_version
        @ssl_version
      end

      def ssl_version=(version)
        raise "Invalid SSL version: '#{version}' supplied! Please supply one as listed in Typhoeus::Easy::SSL_VERSIONS" unless self.class.valid_ssl_version(version)
        @ssl_version = version

        set_option(:sslversion, Typhoeus::Easy::SSL_VERSIONS[version])
      end

      def disable_ssl_peer_verification
        set_option(:verifypeer, 0)
      end

      def disable_ssl_host_verification
        set_option(:verifyhost, 0)
      end

      # Set SSL certificate
      # " The string should be the file name of your certificate. "
      # The default format is "PEM" and can be changed with ssl_cert_type=
      def ssl_cert=(cert)
        set_option(:sslcert, cert)
      end

      # Set SSL certificate type
      # " The string should be the format of your certificate. Supported formats are "PEM" and "DER" "
      def ssl_cert_type=(cert_type)
        raise "Invalid ssl cert type : '#{cert_type}'..." if cert_type and !%w(PEM DER p12).include?(cert_type)
        set_option(:sslcerttype, cert_type)
      end

      # Set SSL Key file
      # " The string should be the file name of your private key. "
      # The default format is "PEM" and can be changed with ssl_key_type=
      #
      def ssl_key=(key)
        set_option(:sslkey, key)
      end

      # Set SSL Key type
      # " The string should be the format of your private key. Supported formats are "PEM", "DER" and "ENG". "
      #
      def ssl_key_type=(key_type)
        raise "Invalid ssl key type : '#{key_type}'..." if key_type and !%w(PEM DER ENG).include?(key_type)
        set_option(:sslkeytype, key_type)
      end

      def ssl_key_password=(key_password)
        set_option(:keypasswd, key_password)
      end

      # Set SSL CACERT
      # " File holding one or more certificates to verify the peer with. "
      #
      def ssl_cacert=(cacert)
        set_option(:cainfo, cacert)
      end

      # Set CAPATH
      # " directory holding multiple CA certificates to verify the peer with. The certificate directory must be prepared using the openssl c_rehash utility. "
      #
      def ssl_capath=(capath)
        set_option(:capath, capath)
      end
    end
  end
end
