module HTTPMachine
  class Filter
    def initialize(options, block)
      @options = options
      @block   = block
    end
    
    def apply_filter?(method_name)
      if @options[:only]
        if @options[:only].instance_of? Symbol
          @options[:only] == method_name
        else
          @options[:only].include?(method_name)
        end
      elsif @options[:except]
        if @options[:except].instance_of? Symbol
          @options[:except] != method_name
        else
          !@options[:except].include?(method_name)
        end
      else
        true
      end
    end
    
    def call(curl_easy)
      @block.call(curl_easy)
    end
  end
end