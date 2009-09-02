module Typhoeus
  class Hydra
    def initialize
      @multi       = Multi.new
      @easy_pool   = []
      @memoized_requests = {}
    end
  
    def self.hydra
      @hydra ||= new
    end

    def queue(request)
      if request.method == :get
        if @memoized_requests.has_key? request.url
          @memoized_requests[request.url] << request
        else
          @memoized_requests[request.url] = []
          get_from_cache_or_queue(request)
        end
      else
        get_from_cache_or_queue(request)
      end
    end

    def run
      @multi.perform
      @memoized_requests = {}
    end
    
    def cache_getter(&block)
      @cache_getter = block
    end
    
    def cache_setter(&block)
      @cache_setter = block
    end
    
    def on_complete(&block)
      @on_complete = block
    end
    
    def get_from_cache_or_queue(request)
      if @cache_getter
        val = @cache_getter.call(request)
        if val
          request.response = val
          request.call_handlers
        else
          @multi.add(get_easy_object(request))
        end
      else
        @multi.add(get_easy_object(request))
      end
    end
    private :get_from_cache_or_queue
        
    def get_easy_object(request)
      easy = @easy_pool.pop || Easy.new
      easy.url          = request.url
      easy.method       = request.method
      easy.headers      = request.headers if request.headers
      easy.request_body = request.body    if request.body
      easy.timeout      = request.timeout if request.timeout
      easy.on_success do |easy|
        handle_request(request, response_from_easy(easy, request))
        @easy_pool.push easy
      end
      easy.on_failure do |easy|
        handle_request(request, response_from_easy(easy, request))
        @easy_pool.push easy
      end
      easy.set_headers
      easy
    end
    private :get_easy_object
    
    def handle_request(request, response)
      request.response = response

      if (request.cache_timeout && @cache_setter)
        @cache_setter.call(request) 
      end      
      @on_complete.call(response) if @on_complete
      
      request.call_handlers
      if requests = @memoized_requests[request.url]
        requests.each do |r|
          r.response = response
          r.call_handlers
        end
      end
    end
    private :handle_request
    
    def response_from_easy(easy, request)
      Response.new(:code    => easy.response_code,
                   :headers => easy.response_header,
                   :body    => easy.response_body,
                   :time    => easy.total_time_taken,
                   :request => request)
    end
    private :response_from_easy
  end
end
