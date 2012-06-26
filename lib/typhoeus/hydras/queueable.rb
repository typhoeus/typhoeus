module Typhoeus
  module Hydras
    module Queueable
      def queued_requests
        @queued_requests ||= []
      end

      def abort
        queued_requests.clear
      end

      def queue(request)
        request.hydra = self
        if multi.easy_handles.size < max_concurrency
          multi.add(Hydras::EasyFactory.new(request, self).get)
        else
          queued_requests << request
        end
      end
    end
  end
end
