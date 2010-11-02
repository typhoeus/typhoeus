require 'uri'

module Typhoeus
  class Request
    attr_reader   :url
    attr_writer   :headers
    attr_accessor :method, :params, :body, :connect_timeout, :timeout,
                  :user_agent, :response, :cache_timeout, :follow_location,
                  :max_redirects, :proxy, :disable_ssl_peer_verification,
                  :ssl_cert, :ssl_cert_type, :ssl_key, :ssl_key_type,
                  :ssl_key_password, :ssl_cacert, :ssl_capath, :verbose,
                  :username, :password, :auth_method, :user_agent

    # Initialize a new Request
    #
    # Options:
    # * +url+ : Endpoint (URL) of the request
    # * +options+   : A hash containing options among :
    # ** +:method+  : :get (default) / :post / :put
    # ** +:params+  : params as a Hash
    # ** +:body+
    # ** +:timeout+ : timeout (ms)
    # ** +:connect_timeout+ : connect timeout (ms)
    # ** +:headers+  : headers as Hash
    # ** +:user_agent+ : user agent (string)
    # ** +:cache_timeout+ : cache timeout (ms)
    # ** +:follow_location
    # ** +:max_redirects
    # ** +:proxy
    # ** +:disable_ssl_peer_verification
    # ** +:ssl_cert
    # ** +:ssl_cert_type
    # ** +:ssl_key
    # ** +:ssl_key_type
    # ** +:ssl_key_password
    # ** +:ssl_cacert
    # ** +:ssl_capath
    # ** +:verbose
    # ** +:username
    # ** +:password
    # ** +:auth_method
    #
    def initialize(url, options = {})
      @method           = options[:method] || :get
      @params           = options[:params]
      @body             = options[:body]
      @timeout          = options[:timeout]
      @connect_timeout  = options[:connect_timeout]
      @headers          = options[:headers] || {}
      @user_agent       = options[:user_agent] || Typhoeus::USER_AGENT
      @cache_timeout    = options[:cache_timeout]
      @follow_location  = options[:follow_location]
      @max_redirects    = options[:max_redirects]
      @proxy            = options[:proxy]
      @disable_ssl_peer_verification = options[:disable_ssl_peer_verification]
      @ssl_cert         = options[:ssl_cert]
      @ssl_cert_type    = options[:ssl_cert_type]
      @ssl_key          = options[:ssl_key]
      @ssl_key_type     = options[:ssl_key_type]
      @ssl_key_password = options[:ssl_key_password]
      @ssl_cacert       = options[:ssl_cacert]
      @ssl_capath       = options[:ssl_capath]
      @verbose          = options[:verbose]
      @username         = options[:username]
      @password         = options[:password]
      @auth_method      = options[:auth_method]

      if @method == :post
        @url = url
      else
        @url = @params ? "#{url}?#{params_string}" : url
      end

      @parsed_uri = URI.parse(@url)

      @on_complete      = nil
      @after_complete   = nil
      @handled_response = nil
    end

    def localhost?
      %(localhost 127.0.0.1 0.0.0.0).include?(@parsed_uri.host)
    end

    def host
      slash_location = @url.index('/', 8)
      if slash_location
        @url.slice(0, slash_location)
      else
        query_string_location = @url.index('?')
        return query_string_location ? @url.slice(0, query_string_location) : @url
      end
    end

    def headers
      @headers["User-Agent"] = @user_agent
      @headers
    end

    def params_string
      params.keys.sort { |a, b| a.to_s <=> b.to_s }.collect do |k|
        value = params[k]
        if value.is_a? Hash
          value.keys.collect {|sk| Typhoeus::Utils.escape("#{k}[#{sk}]") + "=" + Typhoeus::Utils.escape(value[sk].to_s)}
        elsif value.is_a? Array
          key = Typhoeus::Utils.escape(k.to_s)
          value.collect { |v| "#{key}[]=#{Typhoeus::Utils.escape(v.to_s)}" }.join('&')
        else
          "#{Typhoeus::Utils.escape(k.to_s)}=#{Typhoeus::Utils.escape(params[k].to_s)}"
        end
      end.flatten.join("&")
    end

    def on_complete(&block)
      @on_complete = block
    end

    def on_complete=(proc)
      @on_complete = proc
    end

    def after_complete(&block)
      @after_complete = block
    end

    def after_complete=(proc)
      @after_complete = proc
    end

    def call_handlers
      if @on_complete
        @handled_response = @on_complete.call(response)
        call_after_complete
      end
    end

    def call_after_complete
      @after_complete.call(@handled_response) if @after_complete
    end

    def handled_response=(val)
      @handled_response = val
    end

    def handled_response
      @handled_response || response
    end

    def cache_key
      Digest::SHA1.hexdigest(url)
    end

    def self.run(url, params)
      r = new(url, params)
      Typhoeus::Hydra.hydra.queue r
      Typhoeus::Hydra.hydra.run
      r.response
    end

    def self.get(url, params = {})
      run(url, params.merge(:method => :get))
    end

    def self.post(url, params = {})
      run(url, params.merge(:method => :post))
    end

    def self.put(url, params = {})
      run(url, params.merge(:method => :put))
    end

    def self.delete(url, params = {})
      run(url, params.merge(:method => :delete))
    end

    def self.head(url, params = {})
      run(url, params.merge(:method => :head))
    end
  end
end
