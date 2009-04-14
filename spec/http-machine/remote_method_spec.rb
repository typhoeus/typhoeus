require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::RemoteMethod do
  it "should take an http method and options" do
    HTTPMachine::RemoteMethod.new(:get, :body => "foo")
  end
  
  it "should return the http method" do
    m = HTTPMachine::RemoteMethod.new(:put, :body => "asdf")
    m.http_method.should == :put
  end
  
  it "should return the options" do
    m = HTTPMachine::RemoteMethod.new(:delete, :body => "foo")
    m.options.should == {:body => "foo"}
  end
  
  it "should pull uri out of the options hash" do
    m = HTTPMachine::RemoteMethod.new(:delete, {:base_uri => "http://pauldix.net"})
    m.base_uri.should == "http://pauldix.net"
    m.options.should_not have_key(:base_uri)
  end
end