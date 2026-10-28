# frozen_string_literal: true

require 'set'
require 'typhoeus/errors/invalid_option'

module Typhoeus

  # This is a Factory for easies to be used in the hydra.
  # Before an easy is ready to be added to a multi the
  # on_complete callback to be set.
  # This is done by this class.
  #
  # @api private
  class EasyFactory

    RENAMED_OPTIONS =  {
          :auth_method => :httpauth,
          :connect_timeout => :connecttimeout,
          :encoding => :accept_encoding,
          :follow_location => :followlocation,
          :max_redirects => :maxredirs,
          :proxy_type => :proxytype,
          :ssl_cacert => :cainfo,
          :ssl_capath => :capath,
          :ssl_cert => :sslcert,
          :ssl_cert_type => :sslcerttype,
          :ssl_key => :sslkey,
          :ssl_key_password => :keypasswd,
          :ssl_key_type => :sslkeytype,
          :ssl_version => :sslversion,
      }

    CHANGED_OPTIONS =  {
          :disable_ssl_host_verification => :ssl_verifyhost,
          :disable_ssl_peer_verification => :ssl_verifypeer,
          :proxy_auth_method => :proxyauth,
      }

    REMOVED_OPTIONS =  Set.new([:cache_key_basis, :cache_timeout, :user_agent])

    SANITIZE_IGNORE  = Set.new([:method, :cache_ttl, :cache, :set_read_callback])
    SANITIZE_TIMEOUT = Set.new([:timeout_ms, :connecttimeout_ms])
    URL_OPTIONS      = Set.new([:params, :params_encoding, :escape])

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
      @released = false
    end

    # Returns whether the easy was already returned to the pool.
    #
    # @return [ Boolean ]
    #
    # @api private
    def released?
      @released
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
      @released = false
      begin
        read_callback_body = request.options[:set_read_callback]
        easy = self.easy
        url = request.base_url.to_s
        options = sanitize(request.options)
        options.delete(:params) if url.empty?

        easy.http_request(
          url,
          request.options.fetch(:method, :get),
          options
        )

        # this needs to happen after http_request because
        # ethon will set infilesize to zero if form.empty?
        set_read_callback(read_callback_body) if !read_callback_body.nil?
        set_callback
      rescue Exception
        release_easy(@easy) if @easy
        raise
      end
      easy
    end

    # Returns the full request URL without applying unrelated request options.
    # This keeps introspection such as Request#url and the NoStub error working
    # even when another option would be rejected by Ethon.
    #
    # @return [ String ] The URL including params.
    def url
      @released = false
      easy = self.easy
      begin
        url = request.base_url.to_s
        options = sanitize(
          request.options.select { |key, _| URL_OPTIONS.include?(key.to_sym) }
        )
        options.delete(:params) if url.empty?

        easy.http_request(url, :get, options)
        easy.url
      ensure
        release_easy(easy)
      end
    end

    private

    def sanitize(options)
      # set nosignal to true by default
      # this improves thread safety and timeout behavior
      sanitized = {:nosignal => true}
      options.each do |k,v|
        s = k.to_sym
        next if SANITIZE_IGNORE.include?(s)
        if new_option = RENAMED_OPTIONS[k.to_sym]
          warn("Deprecated option #{k}. Please use #{new_option} instead.")
          sanitized[new_option] = v
        elsif new_option = CHANGED_OPTIONS[s]
          raise Errors::InvalidOption.new(
            s,
            "\nPlease try #{new_option} instead of #{s}."
          )
        elsif REMOVED_OPTIONS.include?(s)
          raise Errors::InvalidOption.new(s, "\nThe option #{s} was removed.")
        # sanitize timeouts
        elsif SANITIZE_TIMEOUT.include?(s)
          # An unset value means "no timeout" and never reaches Ethon.
          next if v.nil?

          unless v.is_a?(Numeric)
            raise ArgumentError, "Value '#{v}' for option '#{k}' must be a number."
          end
          if !v.integer?
            warn("Value '#{v}' for option '#{k}' must be integer.")
          end
          sanitized[k] = v.ceil
        else
          sanitized[k] = v
        end
      end

      sanitize_timeout!(sanitized, :timeout)
      sanitize_timeout!(sanitized, :connecttimeout)

      sanitized
    end

    def sanitize_timeout!(options, timeout)
      timeout_ms = :"#{timeout}_ms"
      value = options[timeout]
      return options if value.nil?

      unless value.is_a?(Numeric)
        raise ArgumentError, "Value '#{value}' for option '#{timeout}' must be a number."
      end

      if value.round != value
        if !options[timeout_ms]
          options[timeout_ms] = (value*1000).ceil
        end
        options[timeout] = value.ceil
      end

      # CURLOPT_TIMEOUT and CURLOPT_TIMEOUT_MS set the same value, so libcurl
      # uses the one that is applied last. Keep the millisecond option last:
      # an explicit timeout_ms must also win over a timeout added from Config.
      if options.key?(timeout_ms)
        options[timeout_ms] = options.delete(timeout_ms)
      end
      options
    end

    public

    # Releases the easy into the pool once. Easies that used a custom
    # resolve list are cleaned up instead because libcurl keeps the
    # resolved addresses in its DNS cache across resets.
    #
    # @param [ Ethon::Easy ] easy The easy to release.
    #
    # @return [ void ]
    #
    # @api private
    def release_easy(easy)
      return if released?

      begin
        Typhoeus::Pool.release(easy, :cleanup => !request.options[:resolve].nil?)
      ensure
        @released = true
      end
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
      if request.streaming?
        response = nil
        easy.on_headers do |easy|
          response = Response.new(Ethon::Easy::Mirror.from_easy(easy).options)
          request.execute_headers_callbacks(response)
        end
        request.on_body.each do |callback|
          easy.on_body do |chunk, easy|
            callback.call(chunk, response)
          end
        end
      else
        easy.on_headers do |easy|
          request.execute_headers_callbacks(Response.new(Ethon::Easy::Mirror.from_easy(easy).options))
        end
      end
      (Typhoeus.on_progress + request.on_progress).each do |callback|
        easy.on_progress do |dltotal, dlnow, ultotal, ulnow, _easy|
          callback.call(dltotal, dlnow, ultotal, ulnow)
        end
      end
      easy.on_complete do |easy|
        begin
          request.finish(Response.new(easy.mirror.options))
        ensure
          release_easy(easy)
        end
        if hydra && !hydra.queued_requests.empty?
          hydra.dequeue_many
        end
      end
    end

    # Sets up an easy upload with CURLOPT_READFUNCTION
    # along with CURLOPT_INFILESIZE_LARGE and CURLOPT_UPLOAD
    #
    # @param [ String/File ] body The body read by the readfunction.
    #
    # @return [ Ethon::Easy ] The easy.
    def set_read_callback(body)
      # Uploading a file means sending it from the beginning. An IO that was
      # already read from would otherwise be shorter than the advertised
      # infilesize and libcurl would fail with a read error.
      rewind_body(body)

      easy.infilesize_large =
        if body.respond_to?(:bytesize)
          body.bytesize
        elsif body.respond_to?(:size)
          body.size
        end

      easy.upload = true
      easy.set_read_callback(body)

      easy
    end

    # Rewind a seekable body so the read callback starts at its first byte.
    # Pipes and other non-seekable bodies do not respond to rewind.
    #
    # @param [ Object ] body The body to rewind.
    #
    # @return [ void ]
    def rewind_body(body)
      return unless body.respond_to?(:rewind)

      body.rewind
    rescue IOError, SystemCallError
      # A body that cannot be rewound is still usable from its current
      # position. Do not turn that into a request setup error.
      nil
    end
  end
end
