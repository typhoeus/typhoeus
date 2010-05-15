module Typhoeus
  class Hydra
    def initialize(options = {})
      @memoize_requests = true
      @multi       = Multi.new
      @easy_pool   = []
      initial_pool_size = options[:initial_pool_size] || 10
      @max_concurrency = options[:max_concurrency] || 200
      initial_pool_size.times { @easy_pool << Easy.new }
      @stubs       = []
      @memoized_requests = {}
      @retrieved_from_cache = {}
      @queued_requests = []
      @running_requests = 0
      @stubbed_request_count = 0
    end

    def self.hydra
      @hydra ||= new
    end

    def self.hydra=(val)
      @hydra = val
    end

    def clear_cache_callbacks
      @cache_setter = nil
      @cache_getter = nil
    end

    def clear_stubs
      @stubs = []
    end

    def fire_and_forget
      @queued_requests.each {|r| queue(r, false)}
      @multi.fire_and_forget
    end

    def queue(request, obey_concurrency_limit = true)
      return if assign_to_stub(request)

      if @running_requests >= @max_concurrency && obey_concurrency_limit
        @queued_requests << request
      else
        if request.method == :get
          if @memoize_requests && @memoized_requests.has_key?(request.url)
            if response = @retrieved_from_cache[request.url]
              request.response = response
              request.call_handlers
            else
              @memoized_requests[request.url] << request
            end
          else
            @memoized_requests[request.url] = [] if @memoize_requests
            get_from_cache_or_queue(request)
          end
        else
          get_from_cache_or_queue(request)
        end
      end
    end

    def run
      while @stubbed_request_count > 0
        @stubs.each do |m|
          while request = m.requests.shift
            @stubbed_request_count -= 1
            m.response.request = request
            handle_request(request, m.response)
          end
        end
      end

      @multi.perform
      @memoized_requests = {}
      @retrieved_from_cache = {}
    end

    def disable_memoization
      @memoize_requests = false
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
      @running_requests += 1

      easy = @easy_pool.pop || Easy.new
      easy.url          = request.url
      easy.method       = request.method
      easy.params       = request.params  if request.method == :post && !request.params.nil?
      easy.headers      = request.headers if request.headers
      easy.request_body = request.body    if request.body
      easy.timeout      = request.timeout if request.timeout
      easy.follow_location = request.follow_location if request.follow_location
      easy.max_redirects = request.max_redirects if request.max_redirects
      easy.proxy = request.proxy if request.proxy
      easy.disable_ssl_peer_verification if request.disable_ssl_peer_verification

      easy.on_success do |easy|
        queue_next
        handle_request(request, response_from_easy(easy, request))
        release_easy_object(easy)
      end
      easy.on_failure do |easy|
        queue_next
        handle_request(request, response_from_easy(easy, request))
        release_easy_object(easy)
      end
      easy.set_headers
      easy
    end
    private :get_easy_object

    def queue_next
      @running_requests -= 1
      queue(@queued_requests.pop) unless @queued_requests.empty?
    end
    private :queue_next

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
                   :effective_url => easy.effective_url,
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

    def matches?(request)
      if url.kind_of?(String)
        request.method == method && request.url == url
      else
        request.method == method && url =~ request.url
      end
    end
  end
end
