module Typhoeus
  class Multi
    def remove(easy)
      multi_remove_handle(easy)
    end
    
    def add(easy)
      multi_add_handle(easy)
    end
    
    def perform()
      while active_handle_count > 0 do
        multi_perform
      end
    end
    
    def cleanup()
      multi_cleanup
    end
  end
end