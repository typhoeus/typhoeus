require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::Easy do
  before(:all) do
    @pid = start_method_server(3002)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end
  
  describe "options" do
    it "should allow for following redirects"
    it "should allow you to set the user agent"
    it "should provide a timeout in milliseconds" do
      pid = start_method_server(3001, 5)
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001"
      e.method = :get
      e.timeout = 50
      e.perform
      puts e.response_code
      puts e.total_time_taken
#      e.timed_out?.should == true
      stop_method_server(pid)
    end
  end
  
  describe "get" do
    it "should perform a get" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :get
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=GET")
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :get
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end

  describe "put" do
    it "should perform a put" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :put
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=PUT")      
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :put
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end
  
  describe "post" do
    it "should perform a post" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=POST")      
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
    
    it "should handle params" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.params = {:foo => "bar"}
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("foo=bar")
    end
  end
  
  describe "delete" do
    it "should perform a delete" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=DELETE")
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end  
end