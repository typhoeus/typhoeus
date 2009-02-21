module HTTPMachine
  class IsolatedBlock
    def self.run_isolated(*args, &block)
      
      # make dupes and freeze them
      args.each {|arg| arg.freeze}
      # instance_variables.each do |variable|
      #   instance_variable_set(variable, instance_variable_get(variable).dup.freeze)
      # end
      
      new.instance_eval &block
    end
  end
end