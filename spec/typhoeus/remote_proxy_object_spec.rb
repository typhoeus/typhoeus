require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::RemoteProxyObject do
  before(:each) do
    @easy = Typhoeus::Easy.new
    @easy.method = :get
    @easy.url    = "http://localhost:3001"
    @klass = Class.new do
      def self.clear_memoized_proxy_objects
      end
    end
  end
      
  before(:all) do
    @pid = start_method_server(3001)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end
  
  it "should take a caller and call the clear_memoized_proxy_objects" do
    @klass.should_receive(:clear_memoized_proxy_objects)
    easy = Typhoeus::RemoteProxyObject.new(@klass, @easy)
    easy.response_code.should == 200
  end

  it "should take an easy object and return the body when requested" do
    easy = Typhoeus::RemoteProxyObject.new(@klass, @easy)
    @easy.response_code.should == 0
    easy.response_code.should == 200
  end
  
  it "should perform requests only on the first access" do
    easy = Typhoeus::RemoteProxyObject.new(@klass, @easy)
    easy.response_code.should == 200
    Typhoeus.should_receive(:perform_easy_requests).exactly(0).times
    easy.response_code.should == 200
  end
  
  it "should call the on_success method with an easy object and proxy to the result of on_success" do
    klass = Class.new do
      def initialize(e)
        @easy = e
      end
      
      def blah
        @easy.response_code
      end
    end
    
    k = Typhoeus::RemoteProxyObject.new(@klass, @easy, :on_success => lambda {|e| klass.new(e)})
    k.blah.should == 200
  end
  
  it "should call the on_failure method with an easy object and proxy to the result of on_failure" do
    klass = Class.new do
      def initialize(e)
        @easy = e
      end
      
      def blah
        @easy.response_code
      end
    end
    @easy.url = "http://localhost:3002" #bad port
    k = Typhoeus::RemoteProxyObject.new(@klass, @easy, :on_failure => lambda {|e| klass.new(e)})
    k.blah.should == 0
  end
end