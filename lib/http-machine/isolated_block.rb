module HTTPMachine
  class IsolatedBlock
    def self.run_isolated(*args, &block)
      
      new.instance_eval do
        # make dupes and freeze them
        instance_variables.each do |variable|
          instance_variable_set(variable, instance_variable_get(variable).dup.freeze)
        end
        
        instance_eval &block
      end
    end
  end
end