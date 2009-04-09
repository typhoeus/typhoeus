require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::Easy do
  before(:all) do
    @pid = start_method_server(3002)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end
  
  describe "get" do
    it "should perform a get" do
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :get
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=GET")
    end
    
    it "should send a request body" do
      easy = HTTPMachine::Easy.new
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
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :put
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=PUT")      
    end
    
    it "should send a request body" do
      easy = HTTPMachine::Easy.new
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
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=POST")      
    end
    
    it "should send a request body" do
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end
  
  describe "delete" do
    it "should perform a delete" do
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=DELETE")
    end
    
    it "should send a request body" do
      easy = HTTPMachine::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end  
end