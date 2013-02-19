module Typhoeus

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
    def initialize(request, hydra = nil)
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
      @easy ||= Typhoeus::Pool.get
    end

    # Fabricated easy.
    #
    # @example Prepared easy.
    #   easy_factory.get
    #
    # @return [ Ethon::Easy ] The easy.
    def get
      begin
        easy.http_request(
          request.base_url,
          request.options.fetch(:method, :get),
          request.options.reject{ |k,_| [:method, :cache_ttl].include?(k) }
        )
      rescue Ethon::Errors::InvalidOption => e
        help = provide_help(e.message.match(/:\s(\w+)/)[1])
        raise $!, "#{$!}#{help}", $!.backtrace
      end
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
        Typhoeus::Pool.release(easy)
        if hydra && !hydra.queued_requests.empty?
          hydra.add(hydra.queued_requests.shift)
        end
      end
    end

    def provide_help(option)
      renamed = {
        :auth_method => :httpauth,
        :connect_timeout => :connecttimeout,
        :disable_ssl_host_verification => :ssl_verifyhost,
        :disable_ssl_peer_verification => :ssl_verifypeer,
        :encoding => :accept_encoding,
        :follow_location => :followlocation,
        :max_redirects => :maxredirs,
        :password => :userpwd,
        :proxy_auth_method => :proxyauth,
        :proxy_password => :proxyuserpwd,
        :proxy_type => :proxytype,
        :proxy_username => :proxyuserpwd,
        :ssl_cacert => :cainfo,
        :ssl_capath => :capath,
        :ssl_cert => :sslcert,
        :ssl_cert_type => :sslcerttype,
        :ssl_key => :sslkey,
        :ssl_key_password => :keypasswd,
        :ssl_key_type => :sslkeytype,
        :ssl_version => :sslversion,
        :username => :userpwd
      }
      removed = [:cache_key_basis, :cache_timout, :user_agent]
      if new_option = renamed[option.to_sym]
        "\nPlease try #{new_option} instead of #{option}." if new_option
      elsif removed.include?(option.to_sym)
        "\nThe option #{option} was removed."
      end
    end
  end
end
