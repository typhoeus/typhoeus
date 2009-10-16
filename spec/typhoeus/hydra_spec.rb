require File.dirname(__FILE__) + '/../spec_helper'

# some of these tests assume that you have some local services running.
# ruby spec/servers/app.rb -p 3000
# ruby spec/servers/app.rb -p 3001
# ruby spec/servers/app.rb -p 3002
describe Typhoeus::Hydra do
  before(:all) do
    cache_class = Class.new do
      def initialize
        @cache = {}
      end
      def get(key)
        @cache[key]
      end
      def set(key, object, timeout = 0)
        @cache[key] = object
      end
    end
    @cache = cache_class.new
  end

  it "has a singleton" do
    Typhoeus::Hydra.hydra.should be_a Typhoeus::Hydra
  end
  
  it "has a setter for the singleton" do
    Typhoeus::Hydra.hydra = :foo
    Typhoeus::Hydra.hydra.should == :foo
  end

  context "#stub" do
    before do
      @hydra = Typhoeus::Hydra.new
      @on_complete_handler_called = nil
      @request  = Typhoeus::Request.new("http://localhost:3000/foo")
      @request.on_complete do |response|
        @on_complete_handler_called = true
        response.code.should == 404
        response.headers.should == "whatever"
      end
      @response = Typhoeus::Response.new(:code => 404, :headers => "whatever", :body => "not found", :time => 0.1)
    end

    it "stubs requests to a specific URI" do
      @hydra.stub(:get, "http://localhost:3000/foo").and_return(@response)
      @hydra.queue(@request)
      @hydra.run
      @on_complete_handler_called.should be_true
      @response.request.should == @request
    end
    
    it "stubs requests to URIs matching a pattern" do
      @hydra.stub(:get, /foo/).and_return(@response)
      @hydra.queue(@request)
      @hydra.run
      @on_complete_handler_called.should be_true
      @response.request.should == @request
    end
    
    it "can clear stubs" do
      @hydra.clear_stubs
    end

    it "matches a stub only when the HTTP method also matches"
  end

  it "queues a request" do
    hydra = Typhoeus::Hydra.new
    hydra.queue Typhoeus::Request.new("http://localhost:3000")
  end

  it "runs a batch of requests" do
    hydra  = Typhoeus::Hydra.new
    first  = Typhoeus::Request.new("http://localhost:3000/first")
    second = Typhoeus::Request.new("http://localhost:3001/second")
    hydra.queue first
    hydra.queue second
    hydra.run
    first.response.body.should include("first")
    second.response.body.should include("second")
  end

  it "has a cache_setter proc" do
    hydra = Typhoeus::Hydra.new
    hydra.cache_setter do |request|
      # @cache.set(request.cache_key, request.response, request.cache_timeout)
    end
  end

  it "has a cache_getter" do
    hydra = Typhoeus::Hydra.new
    hydra.cache_getter do |request|
      # @cache.get(request.cache_key) rescue nil
    end
  end

  it "memoizes GET reqeusts" do
    hydra  = Typhoeus::Hydra.new
    first  = Typhoeus::Request.new("http://localhost:3000/foo", :params => {:delay => 1})
    second = Typhoeus::Request.new("http://localhost:3000/foo", :params => {:delay => 1})
    hydra.queue first
    hydra.queue second
    start_time = Time.now
    hydra.run
    first.response.body.should include("foo")
    first.handled_response.body.should include("foo")
    first.response.should == second.response
    first.handled_response.should == second.handled_response
    (Time.now - start_time).should < 1.2 # if it had run twice it would be ~ 2 seconds
  end

  it "pulls GETs from cache" do
    hydra  = Typhoeus::Hydra.new
    start_time = Time.now
    hydra.cache_getter do |request|
      @cache.get(request.cache_key) rescue nil
    end
    hydra.cache_setter do |request|
      @cache.set(request.cache_key, request.response, request.cache_timeout)
    end

    first  = Typhoeus::Request.new("http://localhost:3000/foo", :params => {:delay => 1})
    @cache.set(first.cache_key, :foo, 60)
    hydra.queue first
    hydra.run
    (Time.now - start_time).should < 0.1
    first.response.should == :foo
  end

  it "sets GET responses to cache when the request has a cache_timeout value" do
    hydra  = Typhoeus::Hydra.new
    hydra.cache_getter do |request|
      @cache.get(request.cache_key) rescue nil
    end
    hydra.cache_setter do |request|
      @cache.set(request.cache_key, request.response, request.cache_timeout)
    end

    first  = Typhoeus::Request.new("http://localhost:3000/first", :cache_timeout => 0)
    second = Typhoeus::Request.new("http://localhost:3000/second")
    hydra.queue first
    hydra.queue second
    hydra.run
    first.response.body.should include("first")
    @cache.get(first.cache_key).should == first.response
    @cache.get(second.cache_key).should be_nil
  end

  it "has a global on_complete" do
    foo = nil
    hydra  = Typhoeus::Hydra.new
    hydra.on_complete do |response|
      foo = :called
    end

    first  = Typhoeus::Request.new("http://localhost:3000/first")
    hydra.queue first
    hydra.run
    first.response.body.should include("first")
    foo.should == :called
  end

  it "has a global on_omplete setter" do
    foo = nil
    hydra  = Typhoeus::Hydra.new
    proc = Proc.new {|response| foo = :called}
    hydra.on_complete = proc

    first  = Typhoeus::Request.new("http://localhost:3000/first")
    hydra.queue first
    hydra.run
    first.response.body.should include("first")
    foo.should == :called
  end

  it "should reuse connections from the pool for a host"

  it "should queue up requests while others are running" do
    hydra   = Typhoeus::Hydra.new

    start_time = Time.now
    @responses = []

    request = Typhoeus::Request.new("http://localhost:3000/first", :params => {:delay => 1})
    request.on_complete do |response|
      @responses << response
      response.body.should include("first")
    end

    request.after_complete do |object|
      second_request = Typhoeus::Request.new("http://localhost:3001/second", :params => {:delay => 2})
      second_request.on_complete do |response|
        @responses << response
        response.body.should include("second")
      end
      hydra.queue second_request
    end
    hydra.queue request

    third_request = Typhoeus::Request.new("http://localhost:3002/third", :params => {:delay => 3})
    third_request.on_complete do |response|
      @responses << response
      response.body.should include("third")
    end
    hydra.queue third_request

    hydra.run
    @responses.size.should == 3
    (Time.now - start_time).should < 3.3
  end
end
