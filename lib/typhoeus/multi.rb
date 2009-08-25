module Typhoeus
  class Multi
    attr_reader :easy_handles

    def initialize
      reset_easy_handles
    end

    def remove(easy)
      multi_remove_handle(easy)
    end
    
    def add(easy)
      @easy_handles << easy
      multi_add_handle(easy)
    end
    
    def perform()
      while active_handle_count > 0 do
        multi_perform
      end
      reset_easy_handles
    end
    
    def cleanup()
      multi_cleanup
    end

    private
    def reset_easy_handles
      @easy_handles = []
    end
  end
end
