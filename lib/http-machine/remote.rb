module HTTPMachine
  USER_AGENT = "HTTPMachine - http://github.com/pauldix/http-machine/tree/master"
  
  def self.included(base)
    base.extend ClassMethods
  end
    
  module ClassMethods
    def get(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :get, options, block))
      else
        HTTPMachine.service_access do
          get(url, options, &block)
        end
      end
    end
    
    def post(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :post, options, block))
      else
        HTTPMachine.service_access do
          post(url, options, &block)
        end
      end
    end

    def put(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :put, options, block))
      else
        HTTPMachine.service_access do
          put(url, options, &block)
        end
      end      
    end
    
    def delete(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :delete, options, block))
      else
        HTTPMachine.service_access do
          delete(url, options, &block)
        end
      end
    end
    
    def base_easy_object(url, method, options, block)
      easy = HTTPMachine::Easy.new
      
      easy.url                   = url
      easy.method                = method
      easy.headers["User-Agent"] = (options[:user_agent] || HTTPMachine::USER_AGENT)
      easy.params                = options[:params] if options[:params]
      easy.request_body          = options[:body] if options[:body]
      easy.on_success            = block
      easy.on_failure            = block
      
      easy
    end
    
    def remote_server(server)
      @server = server
    end
    
    def add_multi_request(method_name, params, block)
      all_params = @methods[method_name][:params].merge(params)
      params_string = all_params.to_a.map {|a| a.map {|o|o.to_s}.join("=")}.join("&")
      url = "#{@server}?#{params_string}"
      easy = Curl::Easy.new(url) do |curl|
        curl.headers["User-Agent"] = "HTTPMachine - http://github.com/pauldix/http-machine/tree/master"
        curl.on_success do |c|
          block.functionally.call(send(@methods[method_name][:response_handler], c.body_str))
        end
      end
      Thread.current[:curl_multi].add(easy)
    end

    def remote_method(name, args = {})
      args[:method] ||= :get
      args[:params] ||= {}
      @methods ||= {}
      @methods[name] = args
      puts name
      class_eval <<-SRC
        def self.#{name.to_s}(params, &block)
          add_multi_request(:#{name.to_s}, params, block)
        end
      SRC
    end
  end # ClassMethods
end