require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine do
  before(:each) do
    @klass = Class.new do
      include HTTPMachine
    end
  end
  
  it "should add a get method" do
    response_block = mock("response_block")
    response_block.should_receive(:called)
    
    run_method_server(3001) do
      @klass.get("http://localhost:3001/posts.xml") do |response_code, response|
        response_block.called
        response_code.should == 200
        response.should include("REQUEST_METHOD=GET")
        response.should include("REQUEST_URI=/posts.xml")
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
        response.should include("post%5Bbody%5D=a%20body&post%5Bauthor%5D=paul&post%5Btitle%5D=a%20title")
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
      post_field = post_fields.first
      post_field.name.should == "foo"
      post_field.content.should == "bar"
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