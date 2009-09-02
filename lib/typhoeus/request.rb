module Typhoeus
  class Request
    attr_accessor :method, :host, :path, :params, :body, :headers, :timeout, :user_agent, :response, :cache
    
    def initialize(options = {})
      @method     = options[:method] || :get
      @host       = options[:host]
      @path       = options[:path]
      @params     = options[:params]
      @body       = options[:body]
      @timeout    = options[:timeout]
      @headers    = options[:headers] || {}
      @user_agent = options[:user_agent] || Typhoeus::USER_AGENT
      @cache      = options[:cache]
    end
    
    def headers
      @headers["User-Agent"] = @user_agent
      @headers
    end
    
    def url
      return @url if @url
      @url = @host
      @url << @path if @path
      @url << "?#{params_string}" if (@params && @method == :get)
      @url
    end
    
    def params_string
      params.keys.sort.collect do |k|
        value = params[k]
        if value.is_a? Hash
          value.keys.collect {|sk| CGI.escape("#{k}[#{sk}]") + "=" + CGI.escape(value[sk].to_s)}
        elsif value.is_a? Array
          key = CGI.escape(k.to_s)
          value.collect { |v| "#{key}=#{CGI.escape(v.to_s)}" }.join('&')
        else
          "#{CGI.escape(k.to_s)}=#{CGI.escape(params[k].to_s)}"
        end
      end.flatten.join("&")
    end
    
    def on_complete(&block)
      @on_complete = block
    end
    
    def after_complete(&block)
      @after_complete = block
    end
    
    def call_handlers
      if @on_complete
        @handled_response = @on_complete.call(response)
        @after_complete.call(@handled_response) if @after_complete
      end
    end
    
    def handled_response
      @handled_response
    end
    
    def cache_key
      Digest::SHA1.hexdigest(url)
    end
    
    def inspect
      {:path => path, :params => params}.inspect
    end
  end
end