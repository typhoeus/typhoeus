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
  end # get
  
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
  end # post
  
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
  end # after_filter
  
  describe "#remote_method" do
    before(:each) do
      @klass = Class.new do
        include HTTPMachine
      end
    end
    
    describe "defined methods" do
      before(:each) do
        @klass.instance_eval do
          remote_method :do_stuff
        end
      end

      it "should take a method name as the first argument and define that as a class method" do
        @klass.should respond_to(:do_stuff)
      end
      
      it "should optionally take arguments" do
        @klass.should_receive(:get)
        @klass.do_stuff
      end
      
      it "should take arguments" do
        @klass.should_receive(:get).with("", {:params=>{:foo=>"bar"}, :body=>"whatever"})
        @klass.do_stuff(:params => {:foo => "bar"}, :body => "whatever")
      end
    end

    describe "base_uri" do
      it "should take a :uri as an argument" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://pauldix.net"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net", {})
        @klass.do_stuff
      end
      
      it "should use default_base_uri if no base_uri provided" do
        @klass.instance_eval do
          default_base_uri "http://kgb.com"
          remote_method :do_stuff
        end
        
        @klass.should_receive(:get).with("http://kgb.com", {})
        @klass.do_stuff
      end
      
      it "should override default_base_uri if uri argument is provided" do
        @klass.instance_eval do
          default_base_uri "http://kgb.com"
          remote_method :do_stuff, :base_uri => "http://pauldix.net"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net", {})
        @klass.do_stuff        
      end
    end
    
    describe "path" do
      it "should take :path as an argument" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://kgb.com", :path => "/default.html"
        end
        
        @klass.should_receive(:get).with("http://kgb.com/default.html", {})
        @klass.do_stuff
      end
      
      it "should use deafult_path if no path provided" do
        @klass.instance_eval do
          default_path "/index.html"
          remote_method :do_stuff, :base_uri => "http://pauldix.net"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net/index.html", {})
        @klass.do_stuff
      end
      
      it "should orverride default_path if path argument is provided" do
        @klass.instance_eval do
          default_path "/index.html"
          remote_method :do_stuff, :base_uri => "http://pauldix.net", :path => "/foo.html"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net/foo.html", {})
        @klass.do_stuff        
      end
      
      it "should map symbols in path to arguments for the remote method" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://pauldix.net", :path => "/posts/:post_id/comments/:comment_id"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net/posts/foo/comments/bar", {})
        @klass.do_stuff("foo", "bar")
      end
    end
    
    describe "method" do
      it "should take :method as an argument" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://pauldix.net", :method => :put
        end
        
        @klass.should_receive(:put).with("http://pauldix.net", {})
        @klass.do_stuff
      end
      
      it "should use :get if no method or default_method exists" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://pauldix.net"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net", {})
        @klass.do_stuff
      end
      
      it "should use default_method if no method provided" do
        @klass.instance_eval do
          default_method :delete
          remote_method :do_stuff, :base_uri => "http://kgb.com"
        end
        
        @klass.should_receive(:delete).with("http://kgb.com", {})
        @klass.do_stuff
      end
      
      it "should override deafult_method if method argument is provided" do
        @klass.instance_eval do
          default_method :put
          remote_method :do_stuff, :base_uri => "http://pauldix.net", :method => :post
        end
        
        @klass.should_receive(:post).with("http://pauldix.net", {})
        @klass.do_stuff
      end
    end
    
    describe "on_success" do
      it "should take :on_success as an argument"
      it "should use default_on_success if no on_success provided"
      it "should override default_on_success if no method is provided"
    end
    
    describe "on_failure" do
      it "should take :on_failure as an argument"
      it "should use default_on_failure if no on_success provided"
      it "should override default_on_failure if no method is provided"      
    end
    
    describe "params" do
      it "should take :params as an argument"
    end
  end # remote_method  
end