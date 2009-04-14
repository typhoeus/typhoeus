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
end