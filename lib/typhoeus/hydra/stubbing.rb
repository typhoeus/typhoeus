module Typhoeus
  class Hydra
    module Stubbing
      def stub(method, url)
        @stubs << HydraMock.new(url, method)
        @stubs.last
      end

      def assign_to_stub(request)
        m = @stubs.detect {|stub| stub.matches? request}
        if m
          m.add_request(request)
          @stubbed_request_count += 1
        else
          nil
        end
      end
      private :assign_to_stub

      def clear_stubs
        @stubs = []
      end
    end
  end
end
