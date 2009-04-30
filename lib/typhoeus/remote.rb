module Typhoeus
  USER_AGENT = "Typhoeus - http://github.com/pauldix/typhoeus/tree/master"
  
  def self.included(base)
    base.extend ClassMethods
  end
    
  module ClassMethods
    def get(url, options = {})
      Typhoeus::RemoteProxyObject.new(base_easy_object(url, :get, options), :on_success => options[:on_success], :on_failure => options[:on_failure])
    end
    
    def post(url, options = {}, &block)
      Typhoeus::RemoteProxyObject.new(base_easy_object(url, :post, options), :on_success => options[:on_success], :on_failure => options[:on_failure])
    end

    def put(url, options = {}, &block)
      if Typhoeus.multi_running?
        Typhoeus.add_easy_request(base_easy_object(url, :put, options, filter_wrapper_block(:put, block)))
      else
        Typhoeus.service_access do
          put(url, options, &block)
        end
      end      
    end
    
    def delete(url, options = {}, &block)
      if Typhoeus.multi_running?
        Typhoeus.add_easy_request(base_easy_object(url, :delete, options, filter_wrapper_block(:delete, block)))
      else
        Typhoeus.service_access do
          delete(url, options, &block)
        end
      end
    end
    
    def base_easy_object(url, method, options)
      easy = Typhoeus::Easy.new
      
      easy.url                   = url
      easy.method                = method
      easy.headers["User-Agent"] = (options[:user_agent] || Typhoeus::USER_AGENT)
      easy.params                = options[:params] if options[:params]
      easy.request_body          = options[:body] if options[:body]
      
      easy
    end
    
    def filter_wrapper_block(method_name, block)
      after_filters = @after_filters || []
      wrapper = lambda do |easy_object|
        after_filters.each do |filter|
          send(filter.method_name, easy_object) if filter.apply_filter?(method_name)
        end
        block.call(easy_object)
      end
    end
    
    def default_base_uri=(default_uri)
      @default_base_uri = default_uri
    end
    
    def default_base_uri(default_uri)
      @default_base_uri = default_uri
    end
    
    def default_path(default_path)
      @default_path = default_path
    end
    
    def default_method(default_method)
      @default_method = default_method
    end
    
    def default_on_success(default_on_success)
      @default_on_success = default_on_success
    end
    
    def default_on_failure(default_on_failure)
      @default_on_failure = default_on_failure
    end
    
    def after_filter(method_name, options = {})
      @after_filters ||= []
      @after_filters << Filter.new(method_name, options)
    end
    
    def call_remote_method(method_name, args, options, block)
      m = @remote_methods[method_name]
      
      base_uri = m.base_uri || @default_base_uri || ""

      if options.has_key? :path
        path = options.delete(:path)
      elsif args.empty?
        path = m.path || @default_path || ""
      else
        path = m.interpolate_path_with_arguments(args)
      end
      
      klass = self
      wrapped_block = lambda do |easy|
        response_code = easy.response_code
        if response_code > 199 && response_code < 300
          if s = m.on_success || @default_on_success
            success_result = klass.send(s, easy)
            m.call_response_blocks(success_result, args, options) if m.memoize_responses?
            set_cache(method_name, m, args, options, success_result) if m.cache_responses?
            block.call(success_result)
          else
            m.call_response_blocks(easy, args, options) if m.memoize_responses?
            set_cache(method_name, m, args, options, easy) if m.cache_responses?
            block.call(easy)
          end
        else
          if f = m.on_failure || @default_on_failure
            block.call(klass.send(f, easy))
          else
            block.call(easy)
          end
        end
      end

      send(m.http_method, base_uri + path, m.merge_options(options), &wrapped_block)
    end
    
    def set_cache(method_name, method_object, args, options, value)
      ttl = method_object.cache_ttl
      if ttl == 0
        @cache_server.set(get_memcache_response_key(method_name, args, options), value) unless @cache_server.nil?
      else
        @cache_server.set(get_memcache_response_key(method_name, args, options), value, ttl) unless @cache_server.nil?
      end
    end
    
    def get_cached_response(remote_method_name, method_object, args, options, block)
      @memoized_cache_results ||= {}
      @memoized_cache_misses  ||= {}
      
      key = get_memcache_response_key(remote_method_name, args, options)
      # first see if it's memoized
      response = @memoized_cache_results[key]
      
      # now check if it's in the cache
      if response.nil? && @memoized_cache_misses[key].nil?
        response = @cache_server.get(key) rescue nil
        @memoized_cache_results[key] = response unless response.nil?
      end
      
      # now set it as a miss if appropriate
      @memoized_cache_misses[key] = true unless response
      
      # now set the callback to clear the memoized values
      unless @memoize_clear_block_added
        Typhoeus.add_after_service_access_callback do
          @memoize_clear_block_added = false
          @memoized_cache_results    = {}
          @memoized_cache_misses     = {}
        end
      end
      @memoize_clear_block_added = true
      
      response
    end
    
    def get_memcache_response_key(remote_method_name, args, options)
      result = "#{remote_method_name.to_s}-#{args.to_s}-#{options.to_s}"
      (Digest::SHA2.new << result).to_s
    end
    
    def cache_server=(cache_server)
      @cache_server = cache_server
    end
    
    def remote_method(name, args = {})
      args[:method] ||= @default_method
      m = RemoteMethod.new(args)
      arg_names = m.argument_names_string

      @remote_methods ||= {}
      @remote_methods[name] = m

      class_eval <<-SRC
        def self.#{name.to_s}(#{arg_names}options = {}, &block)
          m = @remote_methods[:#{name.to_s}]
          
          if m.cache_responses?
            res = get_cached_response('#{name.to_s}', m, [#{arg_names}], options, block)
            block.call(res) if res
            return nil if res
          end
          
          if Typhoeus.multi_running?
            if m.memoize_responses?
              if m.already_called?([#{arg_names}], options)
                m.add_response_block(block, [#{arg_names}], options)
              else
                m.calling([#{arg_names}], options)
                call_remote_method(:#{name.to_s}, [#{arg_names}], options, block)
              end
            else
              call_remote_method(:#{name.to_s}, [#{arg_names}], options, block)
            end
          else
            Typhoeus.service_access do
              #{name.to_s}(#{arg_names}options, &block)
            end
          end
        end
      SRC
    end
  end # ClassMethods
end