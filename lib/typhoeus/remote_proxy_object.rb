module Typhoeus
  class RemoteProxyObject
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
    
    def initialize(easy, options = {})
      @easy    = easy
      @success = options[:on_success]
      @failure = options[:on_failure]
      Typhoeus.add_easy_request(@easy)
    end
    
    def method_missing(sym, *args, &block)
      unless @proxied_object
        Typhoeus.perform_easy_requests
        if @easy.response_code >= 200 && @easy.response_code < 300
          @proxied_object = @success.nil? ? @easy : @success.call(@easy)
        else
          @proxied_object = @failure.nil? ? @easy : @failure.call(@easy)
        end
      end
      
      @proxied_object.__send__(sym, *args, &block)
    end
  end
end