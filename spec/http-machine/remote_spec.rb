require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine do
  before(:each) do
    @klass = Class.new do
      include HTTPMachine
    end
  end
  
  describe "get" do
    before(:each) do
      @response_block = mock("response_block")
      @response_block.should_receive(:called)
    end
    
    it "should add a get method" do
      run_method_server(3001) do
        @klass.get("http://localhost:3001/posts.xml") do |response_code, response|
          @response_block.called
          response_code.should == 200
          response.should include("REQUEST_METHOD=GET")
          response.should include("REQUEST_URI=/posts.xml")
        end
      end
    end

    it "should take passed in params and add them to the query string" do
      run_method_server(3001) do
        @klass.get("http://localhost:3001", {:params => {:foo => :bar}}) do |response_code, response|
          @response_block.called
          response.should include("QUERY_STRING=foo=bar")
        end
      end
    end
    
    it "should return the body of the response when no block is passed to get" do
      run_method_server(3001) do
        response = @klass.get("http://localhost:3001/foo.bar")
        response.should inclue("REQUEST_URI=/foo.bar")
      end
    end
  end

  it "should add a post method" do
    response_block = mock("response_block")
    response_block.should_receive(:called)
    
    run_method_server(3001) do
      @klass.post("http://localhost:3001/posts.xml", {:params => {:post => {:author => "paul", :title => "a title", :body => "a body"}}}) do |response_code, response|
        response_block.called
        response_code.should == 200
        response.should include("post%5Bbody%5D=a%20body")
        response.should include("post%5Bauthor%5D=paul")
        response.should include("post%5Btitle%5D=a%20title")
        response.should include("REQUEST_METHOD=POST")
      end
    end
  end
  
  it "should add a put method"
  
  it "should add a delete method" do
    response_block = mock("response_block")
    response_block.should_receive(:called)
    
    run_method_server(3001) do
      @klass.delete("http://localhost:3001/posts/3.xml") do |response_code, response|
        response_block.called
        response_code.should == 200
        response.should include("REQUEST_METHOD=DELETE")
      end
    end
  end
  
  describe "#params_to_curl_post_fields" do
    it "should return a post field with a proper name and value" do
      post_fields = @klass.params_to_curl_post_fields({:foo => :bar, :asdf => :jkl})
      post_fields.detect {|p| p.name == "foo" && p.content == "bar"}.should be
      post_fields.detect {|p| p.name == "asdf" && p.content == "jkl"}.should be
    end
    
    it "should return a post field for nested params" do
      post_fields = @klass.params_to_curl_post_fields({:user => {:email => "paul@pauldix.net", :name => "Paul Dix"}})
      post_fields.first.name.should    == "user[email]"
      post_fields.first.content.should == "paul@pauldix.net"
      post_fields.last.name.should     == "user[name]"
      post_fields.last.content.should  == "Paul Dix"
    end
  end
end