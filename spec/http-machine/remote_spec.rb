require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine do
  before(:each) do
    @klass = Class.new do
      include HTTPMachine
    end
  end
  
  before(:all) do
    @pid = start_method_server(3001)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end

  describe "get" do
    before(:each) do
      @response_block = mock("response_block")
      @response_block.should_receive(:called)
    end
    
    it "should add a get method" do
      @klass.get("http://localhost:3001/posts.xml") do |easy|
        @response_block.called
        easy.response_code.should == 200
        easy.response_body.should include("REQUEST_METHOD=GET")
        easy.response_body.should include("REQUEST_URI=/posts.xml")
      end
    end

    it "should take passed in params and add them to the query string" do
      @klass.get("http://localhost:3001", {:params => {:foo => :bar}}) do |easy|
        @response_block.called
        easy.response_body.should include("QUERY_STRING=foo=bar")
      end
    end
    
  #   it "should return the body of the response when no block is passed to get" do
  #     response = @klass.get("http://localhost:3001/foo.bar")
  #     response.should inclue("REQUEST_URI=/foo.bar")
  #   end
  end
  
  describe "post" do
    it "should add a post method" do
      response_block = mock("response_block")
      response_block.should_receive(:called)

      @klass.post("http://localhost:3001/posts.xml", {:params => {:post => {:author => "paul", :title => "a title", :body => "a body"}}}) do |easy|
        response_block.called
        easy.response_code.should == 200
        easy.response_body.should include("post%5Bbody%5D=a+body")
        easy.response_body.should include("post%5Bauthor%5D=paul")
        easy.response_body.should include("post%5Btitle%5D=a+title")
        easy.response_body.should include("REQUEST_METHOD=POST")
      end
    end

    it "should add a body" do
      response_block = mock("response_block")
      response_block.should_receive(:called)

      @klass.post("http://localhost:3001/posts.xml", {:body => "this is a request body"}) do |easy|
        response_block.called
        easy.response_code.should == 200
        easy.response_body.should include("this is a request body")
        easy.response_body.should include("REQUEST_METHOD=POST")
      end
    end
  end
  
  it "should add a put method" do
    response_block = mock("response_block")
    response_block.should_receive(:called)
    
    @klass.put("http://localhost:3001/posts/3.xml") do |easy|
      response_block.called
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=PUT")
    end
  end
  
  it "should add a delete method" do
    response_block = mock("response_block")
    response_block.should_receive(:called)
    
    @klass.delete("http://localhost:3001/posts/3.xml") do |easy|
      response_block.called
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=DELETE")
    end
  end
  
  describe "after_filter" do
    it "should call an after filter then call the regular block" do
      filter_mock = mock("filter_called")
      filter_mock.should_receive(:call)

      klass = Class.new do
        include HTTPMachine
        after_filter :some_method
        
        @filter_mock = filter_mock
        
        def self.some_method(easy)
          @filter_mock.call
        end
      end
      
      response_block = mock("response_block")
      response_block.should_receive(:called)
      klass.get("http://localhost:3001") do |easy|
        response_block.called
        easy.response_code.should == 200
        easy.response_body.should include("REQUEST_METHOD=GET")
      end
    end
  end
end