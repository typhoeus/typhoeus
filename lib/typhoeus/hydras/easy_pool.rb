module Typhoeus
  module Hydras
    module EasyPool
      def easy_pool
        @easy_pool ||= []
      end

      def release_easy(easy)
        easy.reset
        easy_pool << easy
      end

      def get_easy
        easy_pool.pop || Ethon::Easy.new
      end
    end
  end
end
