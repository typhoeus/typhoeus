module Typhoeus
  module Hydras
    module Runnable
      def run
        multi.perform
      end
    end
  end
end
