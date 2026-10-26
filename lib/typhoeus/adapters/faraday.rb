# frozen_string_literal: true

require 'typhoeus'
require 'faraday'

module Faraday # :nodoc:
  class Adapter # :nodoc:

    # Adapter to use Faraday with Typhoeus.
    #
    # @example Use Typhoeus.
    #   require 'faraday'
    #   require 'typhoeus'
    #   require 'typhoeus/adapters/faraday'
    #
    #   conn = Faraday.new(url: "www.example.com") do |faraday|
    #     faraday.adapter :typhoeus
    #
    #     # You can include Typhoeus options to be used for every request
    #     # faraday.adapter :typhoeus, forbid_reuse: true, maxredirs: 1
    #   end
    #
    #   response = conn.get("/")
    class Typhoeus < Faraday::Adapter
      PathExpectedError = Class.new(StandardError)

      self.supports_parallel = true

      # Initialize the Typhoeus adapter
      #
      # @param [ App ] app Farday app
      # @option [ Hash ] adapter_options Typhoeus options
      #
      # @return [ void ]
      def initialize(app, adapter_options = {})
        super(app)
        @adapter_options = adapter_options
      end

      # Setup Hydra with provided options.
      #
      # @example Setup Hydra.
      #   Faraday::Adapter::Typhoeus.setup_parallel_manager
      #   #=> #<Typhoeus::Hydra ... >
      #
      # @param (see Typhoeus::Hydra#initialize)
      # @option (see Typhoeus::Hydra#initialize)
      #
      # @return [ Typhoeus::Hydra ] The hydra.
      def self.setup_parallel_manager(options = {})
        ::Typhoeus::Hydra.new(options)
      end

      # Hook into Faraday and perform the request with Typhoeus.
      #
      # @param [ Hash ] env The environment.
      #
      # @return [ void ]
      def call(env)
        super
        perform_request env
        @app.call env
      end

      private

      def perform_request(env)
        if parallel?(env)
          env[:parallel_manager].queue request(env)
        else
          request(env).run
        end
      end

      def request(env)
        read_body env

        req = typhoeus_request(env)

        configure_ssl     req, env
        configure_proxy   req, env
        configure_timeout req, env
        configure_socket  req, env

        req.on_complete do |resp|
          if resp.timed_out?
            env[:typhoeus_timed_out] = true
            unless parallel?(env)
              raise Faraday::TimeoutError, "request timed out"
            end
          elsif (resp.response_code == 0) || ((resp.return_code != :ok) && !resp.mock?)
            env[:typhoeus_connection_failed] = true
            env[:typhoeus_return_message] = resp.return_message
            unless parallel?(env)
              raise Faraday::ConnectionFailed, resp.return_message
            end
          end

          save_response(env, resp.code, resp.body, nil, resp.status_message) do |response_headers|
            response_headers.parse resp.response_headers
          end
          # in async mode, :response is initialized at this point
          env[:response].finish(env) if parallel?(env)
        end

        req
      end

      def typhoeus_request(env)
        opts = {
          :method => env[:method],
          :body => env[:body],
          :headers => env[:request_headers]
        }.merge(@adapter_options)

        ::Typhoeus::Request.new(env[:url].to_s, opts)
      end

      def read_body(env)
        env[:body] = env[:body].read if env[:body].respond_to? :read
      end

      def configure_ssl(req, env)
        ssl = env[:ssl]

        verify_p = ssl_option(ssl, :verify, true)
        verify_host = ssl_option(ssl, :verify_hostname, true)

        if verify_p && verify_host
          ssl_verifyhost = req.options.fetch(:ssl_verifyhost, 2)
        else
          ssl_verifyhost = 0
        end

        req.options[:ssl_verifyhost] = ssl_verifyhost
        req.options[:ssl_verifypeer] = verify_p
        ssl_version = ssl_version_for(ssl)
        req.options[:sslversion] = ssl_version if ssl_version

        client_cert = ssl_option(ssl, :client_cert)
        req.options[:sslcert] = path_for(client_cert, :client_cert) if client_cert
        client_key = ssl_option(ssl, :client_key)
        req.options[:sslkey] = path_for(client_key, :client_key) if client_key
        ca_file = ssl_option(ssl, :ca_file)
        req.options[:cainfo] = ca_file if ca_file
        ca_path = ssl_option(ssl, :ca_path)
        req.options[:capath] = ca_path if ca_path

        client_cert_passwd_key = [:client_cert_passwd, :client_certificate_password].detect do |name|
          !ssl_option(ssl, name).nil?
        end
        req.options[:keypasswd] = ssl_option(ssl, client_cert_passwd_key) if client_cert_passwd_key
      end

      # Return an SSL option from a Faraday SSLOptions struct or a Hash.
      # Faraday leaves unset options nil and treats nil as the default, for
      # example `verify_hostname?` is true unless the value is false.
      #
      # @return [ Object ] The option value or the default.
      def ssl_option(ssl, name, default = nil)
        return default unless ssl

        value =
          if ssl.is_a?(Hash)
            ssl.fetch(name, default)
          elsif ssl.respond_to?(name)
            ssl.public_send(name)
          end

        value.nil? ? default : value
      end

      # Translate an OpenSSL/Faraday SSL version to Ethon's spelling.
      #
      # @return [ Symbol, nil ] The Ethon SSL version.
      def ssl_version_for(ssl)
        version = ssl_option(ssl, :version)
        min_version = ssl_option(ssl, :min_version)
        max_version = ssl_option(ssl, :max_version)

        if version.nil? && min_version && min_version == max_version
          version = min_version
        elsif version.nil? && (min_version || max_version)
          raise ArgumentError, "Typhoeus does not support ssl.min_version/max_version"
        end

        return nil unless version

        normalized = version.to_s.downcase.to_sym
        normalized = :default if normalized == :sslv23

        supported = Ethon::Curl.easy_options(nil)[:sslversion][:opts]
        unless supported.key?(normalized)
          raise ArgumentError, "Unknown SSL version #{version.inspect}"
        end

        normalized
      end

      def configure_proxy(req, env)
        proxy = env[:request][:proxy]
        return unless proxy

        req.options[:proxy] = "#{proxy[:uri].scheme}://#{proxy[:uri].host}:#{proxy[:uri].port}"

        if proxy[:user] && proxy[:password]
          req.options[:proxyauth] ||= :basic
          req.options[:proxyuserpwd] = "#{proxy[:user]}:#{proxy[:password]}"
        end
      end

      def configure_timeout(req, env)
        env_req = env[:request]
        req.options[:timeout_ms] = (env_req[:timeout] * 1000).to_i             if env_req[:timeout]
        req.options[:connecttimeout_ms] = (env_req[:open_timeout] * 1000).to_i if env_req[:open_timeout]
      end

      def configure_socket(req, env)
        if bind = env[:request][:bind]
          req.options[:interface] = bind[:host]
        end
      end

      def parallel?(env)
        !!env[:parallel_manager]
      end

      def path_for(value, name)
        return value if value.is_a?(String)
        return value.to_path if value.respond_to?(:to_path)

        raise PathExpectedError, "Typhoeus expects a path for `#{name}`"
      end
    end
  end
end

Faraday::Adapter.register_middleware :typhoeus => :Typhoeus if Faraday::Adapter.respond_to?(:register_middleware)
