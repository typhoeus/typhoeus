require File.dirname(__FILE__) + '/../spec_helper'

describe "hydra" do
  it "queues a request"
  it "has a singleton that queues a request"
  it "runs a batch of requests"
  it "has a singleton that runs a batch of requests"
  it "has a cache setter proc"
  it "has a cache getter"
  it "memoizes reqeusts"
  it "pulls GETs from cache"
  it "sets GET responses to cache"
  
  # this test assumes that you have three servers running locally.
  # ruby spec/servers/app.rb -p 3000
  # ruby spec/servers/app.rb -p 3001
  # ruby spec/servers/app.rb -p 3002
  it "should queue up requests while others are running" do
    hydra   = Typhoeus::Hydra.new

    start_time = Time.now
    @responses = []
    
    request = Typhoeus::Request.new(:method => :get, :host => "localhost:3000", :path => "/first", :params => {:delay => 1})
    request.on_complete 
    request.on_complete do |response|
      @responses << response
      response.body.should include("first")
    end

    request.after_complete do |object|
      second_request = Typhoeus::Request.new(:method => :get, :host => "localhost:3001", :path => "/second", :params => {:delay => 2})
      second_request.on_complete do |response|
        @responses << response
        response.body.should include("second")
      end
      hydra.queue second_request
    end
    hydra.queue request

    third_request = Typhoeus::Request.new(:method => :get, :host => "localhost:3002", :path => "/third", :params => {:delay => 3})
    third_request.on_complete do |response|
      @responses << response
      response.body.should include("third")
    end
    hydra.queue third_request

    hydra.run
    @responses.size.should == 3
    (Time.now - start_time).should < 3.1
  end
end