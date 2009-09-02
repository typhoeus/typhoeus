module Typhoeus
  class Hydra
    def initialize
      @multi       = Multi.new
      @easy_pool   = []
    end
  
    def queue(request)
      @multi.add(get_easy_object(request))
    end
    
    def get_easy_object(request)
      easy = Easy.new #@easy_pool.pop || Easy.new
      easy.url          = request.url
      easy.method       = request.method
      easy.headers      = request.headers if request.headers
      easy.request_body = request.body    if request.body
      easy.timeout      = request.timeout if request.timeout
      easy.on_success do |easy|
        request.response = response_from_easy(easy)
        request.call_handlers
#        @easy_pool.push(easy)
      end
      easy.on_failure do |easy|
        request.response = response_from_easy(easy)
        request.call_handlers
#        @easy_pool.push(easy)
      end
      easy.set_headers
      easy
    end
    
    def response_from_easy(easy)
      Response.new(:code    => easy.response_code,
                   :headers => easy.response_header,
                   :body    => easy.response_body,
                   :time    => easy.total_time_taken)
    end
    
    def run
      @multi.perform
    end
  end
end
