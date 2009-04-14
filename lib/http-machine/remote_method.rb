module HTTPMachine
  class RemoteMethod
    attr_accessor :http_method, :options, :base_uri
    
    def initialize(http_method, options)
      @http_method = http_method
      @options     = options
      @base_uri    = options.delete(:base_uri)
    end
  end
end