module Typhoeus
  class RemoteProxyObject
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
    
    def initialize(clear_memoized_store_proc, easy, options = {})
      @clear_memoized_store_proc = clear_memoized_store_proc
      @easy      = easy
      @success   = options[:on_success]
      @failure   = options[:on_failure]
      @cache     = options.delete(:cache)
      @cache_key = options.delete(:cache_key)
      @timeout   = options.delete(:cache_timeout)
      Typhoeus.add_easy_request(@easy)
    end
    
    def method_missing(sym, *args, &block)
      unless @proxied_object
        if @cache && @cache_key
          @proxied_object = @cache.get(@cache_key)
        end
        
        unless @proxied_object
          Typhoeus.perform_easy_requests
          if @easy.response_code >= 200 && @easy.response_code < 300
            @proxied_object = @success.nil? ? @easy : @success.call(@easy)
            if @cache && @cache_key
              @cache.set(@cache_key, @proxied_object, @timeout)
            end
          else
            @proxied_object = @failure.nil? ? @easy : @failure.call(@easy)
          end
         @clear_memoized_store_proc.call
       end
      end
      
      @proxied_object.__send__(sym, *args, &block)
    end
  end
end