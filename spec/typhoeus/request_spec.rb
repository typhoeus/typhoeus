require File.dirname(__FILE__) + '/../spec_helper'

describe "request" do
  it "has a host" do
    request = Typhoeus::Request.new(:host => "http://localhost:3000")
    request.host.should == "http://localhost:3000"
  end
  
  it "has a path" do
    request = Typhoeus::Request.new(:path => "/foo")
    request.path.should == "/foo"
  end
  
  it "has a method" do
    request = Typhoeus::Request.new(:method => :get)
    request.method.should == :get
  end
  
  it "has headers" do
    headers = {:foo => :bar}
    request = Typhoeus::Request.new(:headers => headers)
    request.headers.should == headers
  end
  
  it "can take params" do
  end
  
  it "has a body" do
    request = Typhoeus::Request.new(:body => "whatever")
    request.body.should == "whatever"
  end
  
  it "has a timeout" do
    request = Typhoeus::Request.new(:timeout => 10)
    request.timeout.should == 10
  end
  
  it "has a cache timeout" do
    request = Typhoeus::Request.new(:cache => 60)
    request.cache.should == 60
  end
  
  it "has the associated response object" do
    request = Typhoeus::Request.new
    request.response = :foo
    request.response.should == :foo    
  end

  it "can generate a url" do
    request = Typhoeus::Request.new(:host => "http://localhost:3000", :path => "/foo", :params => {:q => "test"})
    request.url.should == "http://localhost:3000/foo?q=test"
  end
  
  it "has an on_complete handler that is called when the request is completed" do
    request = Typhoeus::Request.new
    foo = nil
    request.on_complete do |response|
      foo = response
    end
    request.response = :bar
    request.call_handlers
    foo.should == :bar
  end
  
  it "stores the handled response that is the return value from the on_complete block" do
    request = Typhoeus::Request.new
    request.on_complete do |response|
      "handled"
    end
    request.response = :bar
    request.call_handlers
    request.handled_response.should == "handled"
  end
  
  it "has an after_complete handler that recieves what on_complete returns" do
    request = Typhoeus::Request.new
    request.on_complete do |response|
      "handled"
    end
    good = nil
    request.after_complete do |object|
      good = object == "handled"
    end
    request.call_handlers
    good.should be_true
  end
end