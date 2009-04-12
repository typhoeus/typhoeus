module HTTPMachine
  class Multi
    def remove(easy)
      multi_remove_handle(easy)
    end
    
    def add(easy)
      multi_add_handle(easy)
    end
    
    def perform()
      multi_perform
    end
    
    def cleanup()
      multi_cleanup
    end
  end
end