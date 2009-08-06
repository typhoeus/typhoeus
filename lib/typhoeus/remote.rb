module Typhoeus
  USER_AGENT = "Typhoeus - http://github.com/pauldix/typhoeus/tree/master"
  
  def self.included(base)
    base.extend ClassMethods
  end

  class MockExpectedError < StandardError; end
    
  module ClassMethods
    def allow_net_connect
      @allow_net_connect = true if @allow_net_connect.nil?
      @allow_net_connect
    end

    def allow_net_connect=(value)
      @allow_net_connect = value
    end
    
    def mock(method, args = {})
      @remote_mocks ||= {}
      @remote_mocks[method] ||= {}
      args[:code]    ||= 200
      args[:body]    ||= ""
      args[:headers] ||= ""
      args[:time]    ||= 0
      url = args.delete(:url)
      url ||= :catch_all
      @remote_mocks[method][url] = args
    end
    
    def get_mock(method, url, options)
      return nil unless @remote_mocks
      if @remote_mocks.has_key? method
        extra_response_args = { :requested_http_method => method,
                                :requested_url => url }
        if @remote_mocks[method].has_key? url
          get_mock_and_run_handlers(method,
                                    @remote_mocks[method][url].merge(
                                      extra_response_args),
                                    options)
        elsif @remote_mocks[method].has_key? :catch_all
          get_mock_and_run_handlers(method,
                                    @remote_mocks[method][:catch_all].merge(
                                      extra_response_args),
                                    options)
        else
          nil
        end
      else
        nil
      end
    end

    def enforce_allow_net_connect!(http_verb, url)
      if !allow_net_connect
        raise MockExpectedError,
              "Real HTTP connections are disabled. Unregistered request: " <<
              "#{http_verb.to_s.upcase} #{url}\n" <<
              "  Try: mock(:#{http_verb}, :url => \"#{url}\")"
      end
    end
    
    def get_mock_and_run_handlers(method, response_args, options)
      response = Response.new(response_args)
     
      if response_args.has_key? :expected_body
        raise "#{method} expected body of \"#{response_args[:expected_body]}\" but received #{options[:body]}" if response_args[:expected_body] != options[:body]
      end
      
      if response_args.has_key? :expected_headers
        raise "#{method} expected body of \"#{response_args[:expected_headers].inspect}\" but received #{options[:headers].inspect}" if response_args[:expected_headers] != options[:headers]
      end
      
      if response.code >= 200 && response.code < 300 && options.has_key?(:on_success)
        response = options[:on_success].call(response)
      elsif options.has_key?(:on_failure)
        response = options[:on_failure].call(response)
      end
      response
    end
    
    def get(url, options = {})
      mock_object = get_mock(:get, url, options)
      unless mock_object.nil?
        mock_object
      else
        enforce_allow_net_connect!(:get, url)  
        remote_proxy_object(url, :get, options)
      end
    end
    
    def post(url, options = {}, &block)
      mock_object = get_mock(:post, url, options)
      unless mock_object.nil?
        mock_object
      else
        enforce_allow_net_connect!(:post, url)
        remote_proxy_object(url, :post, options)
      end
    end

    def put(url, options = {}, &block)
      mock_object = get_mock(:put, url, options)
      unless mock_object.nil?
        mock_object
      else
        enforce_allow_net_connect!(:put, url)
        remote_proxy_object(url, :put, options)
      end
    end
    
    def delete(url, options = {}, &block)
      mock_object = get_mock(:delete, url, options)
      unless mock_object.nil?
        mock_object
      else
        enforce_allow_net_connect!(:delete, url)
        remote_proxy_object(url, :delete, options)
      end
    end
    
    def remote_proxy_object(url, method, options)
      easy = Typhoeus.get_easy_object
      
      easy.url                   = url
      easy.method                = method
      easy.headers               = options[:headers] if options.has_key?(:headers)
      easy.headers["User-Agent"] = (options[:user_agent] || Typhoeus::USER_AGENT)
      easy.params                = options[:params] if options[:params]
      easy.request_body          = options[:body] if options[:body]
      easy.timeout               = options[:timeout] if options[:timeout]
      easy.set_headers
      
      proxy = Typhoeus::RemoteProxyObject.new(clear_memoized_proxy_objects, easy, options)
      set_memoized_proxy_object(method, url, options, proxy)
    end
    
    def remote_defaults(options)
      @remote_defaults ||= {}
      @remote_defaults.merge!(options)
      @remote_defaults
    end

    # If we get subclassed, make sure that child inherits the remote defaults
    # of the parent class.
    def inherited(child)
      child.__send__(:remote_defaults, @remote_defaults)
    end
    
    def call_remote_method(method_name, args)
      m = @remote_methods[method_name]
      
      base_uri = args.delete(:base_uri) || m.base_uri || ""

      if args.has_key? :path
        path = args.delete(:path)
      else
        path = m.interpolate_path_with_arguments(args)
      end
      path ||= ""
      
      http_method = m.http_method
      url         = base_uri + path
      options     = m.merge_options(args)
      
      # proxy_object = memoized_proxy_object(http_method, url, options)
      # return proxy_object unless proxy_object.nil?
      # 
      # if m.cache_responses?
      #   object = @cache.get(get_memcache_response_key(method_name, args))
      #   if object
      #     set_memoized_proxy_object(http_method, url, options, object)
      #     return object
      #   end
      # end

      proxy = memoized_proxy_object(http_method, url, options)
      unless proxy
        if m.cache_responses?
          options[:cache] = @cache
          options[:cache_key] = get_memcache_response_key(method_name, args)
          options[:cache_timeout] = m.cache_ttl
        end
        proxy = send(http_method, url, options)
      end
      proxy
    end
    
    def set_memoized_proxy_object(http_method, url, options, object)
      @memoized_proxy_objects ||= {}
      @memoized_proxy_objects["#{http_method}_#{url}_#{options.to_s}"] = object
    end
    
    def memoized_proxy_object(http_method, url, options)
      @memoized_proxy_objects ||= {}
      @memoized_proxy_objects["#{http_method}_#{url}_#{options.to_s}"]
    end
    
    def clear_memoized_proxy_objects
      lambda { @memoized_proxy_objects = {} }
    end

    def get_memcache_response_key(remote_method_name, args)
      result = "#{remote_method_name.to_s}-#{args.to_s}"
      (Digest::SHA2.new << result).to_s
    end
    
    def cache=(cache)
      @cache = cache
    end
    
    def define_remote_method(name, args = {})
      @remote_defaults  ||= {}
      args[:method]     ||= @remote_defaults[:method]
      args[:on_success] ||= @remote_defaults[:on_success]
      args[:on_failure] ||= @remote_defaults[:on_failure]
      args[:base_uri]   ||= @remote_defaults[:base_uri]
      args[:path]       ||= @remote_defaults[:path]
      m = RemoteMethod.new(args)

      @remote_methods ||= {}
      @remote_methods[name] = m

      class_eval <<-SRC
        def self.#{name.to_s}(args = {})
          call_remote_method(:#{name.to_s}, args)
        end
      SRC
    end
  end # ClassMethods
end
