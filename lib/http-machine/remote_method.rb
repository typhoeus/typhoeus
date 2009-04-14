module HTTPMachine
  class RemoteMethod
    attr_accessor :http_method, :options
    
    def initialize(http_method, options)
      @http_method = http_method
      @options     = options
    end
  end
end