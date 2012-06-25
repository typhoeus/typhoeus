module Typhoeus
  module Hydras
    module Memoizable
      def memory
        @memory ||= {}
      end

      def queue(request)
        if request.memoizable? && memory.has_key?(request)
          request.instance_variable_set(:@response, memory[request])
          request.complete
        else
          super
        end
      end
    end
  end
end
