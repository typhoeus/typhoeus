module Typhoeus
  module Requests
    module Memoizable
      def response=(response)
        hydra.memory[self] = response if memoizable?
        super
      end

      def memoizable?
        Typhoeus::Config.memoize &&
          (options[:method].nil? || options[:method] == :get)
      end
    end
  end
end
