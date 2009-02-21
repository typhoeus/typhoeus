require 'curb'

module HTTPMachine
  def self.included(base)
    base.extend ClassMethods
  end
    
  module ClassMethods
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
          block.call(send(@methods[method_name][:response_handler], c.body_str))
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