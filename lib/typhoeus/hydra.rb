module Typhoeus
  class Hydra
    def initialize
      @multi       = Multi.new
      @easy_pool   = []
      @mocks       = []
      @memoized_requests = {}
      @retrieved_from_cache = {}
    end

    def self.hydra
      @hydra ||= new
    end

    def queue(request)
      return if assign_to_mock(request)

      if request.method == :get
        if @memoized_requests.has_key? request.url
          if response = @retrieved_from_cache[request.url]
            request.response = response
            request.call_handlers
          else
            @memoized_requests[request.url] << request
          end
        else
          @memoized_requests[request.url] = []
          get_from_cache_or_queue(request)
        end
      else
        get_from_cache_or_queue(request)
      end
    end

    def run
      @mocks.each do |m|
        m.requests.each do |request|
          m.response.request = request
          handle_request(request, m.response)
        end
      end
      @multi.perform
      @memoized_requests = {}
      @retrieved_from_cache = {}
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

    def on_complete=(proc)
      @on_complete = proc
    end

    def mock(method, url)
      @mocks << HydraMock.new(url, method)
      @mocks.last
    end

    def assign_to_mock(request)
      m = @mocks.detect {|mck| mck.method == request.method && mck.url == request.url}
      m && m.add_request(request)
    end
    private :assign_to_mock

    def get_from_cache_or_queue(request)
      if @cache_getter
        val = @cache_getter.call(request)
        if val
          @retrieved_from_cache[request.url] = val
          handle_request(request, val, false)
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
        release_easy_object(easy)
      end
      easy.on_failure do |easy|
        handle_request(request, response_from_easy(easy, request))
        release_easy_object(easy)
      end
      easy.set_headers
      easy
    end
    private :get_easy_object

    def release_easy_object(easy)
      easy.reset
      @easy_pool.push easy
    end
    private :release_easy_object

    def handle_request(request, response, live_request = true)
      request.response = response

      if live_request && request.cache_timeout && @cache_setter
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

  class HydraMock
    attr_reader :url, :method, :response, :requests

    def initialize(url, method)
      @url      = url
      @method   = method
      @requests = []
    end

    def add_request(request)
      @requests << request
    end

    def and_return(val)
      @response = val
    end
  end
end
