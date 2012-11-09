module Typhoeus
  class Request

    # This module contains everything what is necessary
    # to make a single request.
    module Operations

      # Run a request.
      #
      # @example Run a request.
      #  Typhoeus::Request.new("www.example.com").run
      #
      # @return [ Response ] The response.
      def run
        easy = Typhoeus.get_easy
        begin
          easy.http_request(
            url,
            options.fetch(:method, :get),
            options.reject{|k,_| k==:method}
          )
        rescue Ethon::Errors::InvalidOption => e
          help = provide_help(e.message.match(/:\s(\w+)/)[1])
          raise $!, "#{$!}#{help}", $!.backtrace
        end
        easy.perform
        finish(Response.new(easy.to_hash))
        Typhoeus.release_easy(easy)
        response
      end

      # Sets a response, the request on the response
      # and executes the callbacks.
      #
      # @param [Typhoeus::Response] response The response.
      # @param [Boolean] bypass_memoization Wether to bypass
      #   memoization or not. Decides how the response is set.
      #
      # @return [Typhoeus::Response] The response.
      def finish(response, bypass_memoization = nil)
        if bypass_memoization
          @response = response
        else
          self.response = response
        end
        self.response.request = self
        execute_callbacks
        response
      end

      private

      def provide_help(option)
        renamed = {
          :connect_timeout => :connecttimeout,
          :follow_location => :followlocation,
          :max_redirects => :maxredirs,
          :proxy_username => :proxyuserpwd,
          :proxy_password => :proxyuserpwd,
          :disable_ssl_peer_verification => :ssl_verifypeer,
          :disable_ssl_host_verification => :ssl_verifyhost,
          :ssl_cert => :sslcert,
          :ssl_cert_type => :sslcerttype,
          :ssl_key => :sslkey,
          :ssl_key_type => :sslkeytype,
          :ssl_key_password => :keypasswd,
          :ssl_cacert => :cainfo,
          :ssl_capath => :capath,
          :ssl_version => :sslversion,
          :username => :userpwd,
          :password => :userpwd,
          :auth_method => :httpauth,
          :proxy_auth_method => :proxyauth,
          :proxy_type => :proxytype
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
end
