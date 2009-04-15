require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::RemoteMethod do
  it "should take options" do
    HTTPMachine::RemoteMethod.new(:body => "foo")
  end
  
  describe "http_method" do
    it "should return the http method" do
      m = HTTPMachine::RemoteMethod.new(:method => :put)
      m.http_method.should == :put
    end
    
    it "should default to :get" do
      m = HTTPMachine::RemoteMethod.new
      m.http_method.should == :get
    end
  end
  
  it "should return the options" do
    m = HTTPMachine::RemoteMethod.new(:body => "foo")
    m.options.should == {:body => "foo"}
  end
  
  it "should pull uri out of the options hash" do
    m = HTTPMachine::RemoteMethod.new(:base_uri => "http://pauldix.net")
    m.base_uri.should == "http://pauldix.net"
    m.options.should_not have_key(:base_uri)
  end
  
  describe "on_success" do
    it "should return method name" do
      m = HTTPMachine::RemoteMethod.new(:on_success => :whatev)
      m.on_success.should == :whatev
    end
    
    it "should pull it out of the options hash" do
      m = HTTPMachine::RemoteMethod.new(:on_success => :whatev)
      m.options.should_not have_key(:on_success)
    end
  end
  
  describe "on_failure" do
    it "should return method name" do
      m = HTTPMachine::RemoteMethod.new(:on_failure => :whatev)
      m.on_failure.should == :whatev
    end
    
    it "should pull it out of the options hash" do
      m = HTTPMachine::RemoteMethod.new(:on_failure => :whatev)
      m.options.should_not have_key(:on_failure)
    end
  end
  
  describe "path" do
    it "should pull path out of the options hash" do
      m = HTTPMachine::RemoteMethod.new(:path => "foo")
      m.path.should == "foo"
      m.options.should_not have_key(:path)
    end
    
    it "should output argument names from the symbols in the path" do
      m = HTTPMachine::RemoteMethod.new(:path => "/posts/:post_id/comments/:comment_id")
      m.argument_names.should == ["post_id", "comment_id"]
    end
    
    it "should output an empty string when there are no arguments in path" do
      m = HTTPMachine::RemoteMethod.new(:path => "/default.html")
      m.argument_names.should == []
    end
    
    it "should output and empty string when there is no path specified" do
      m = HTTPMachine::RemoteMethod.new
      m.argument_names.should == []
    end
    
    it "should provide an empty argument_names string if an empty array" do
      m = HTTPMachine::RemoteMethod.new(:path => "/default.html")
      m.argument_names_string.should == ""
    end
    
    it "should provide an argument_names string with a trailing , if one or more arguments" do
      m = HTTPMachine::RemoteMethod.new(:path => "/posts/:post_id/comments/:comment_id")
      m.argument_names_string.should == "post_id, comment_id, "
    end
    
    it "should interpolate a path with arguments" do
      m = HTTPMachine::RemoteMethod.new(:path => "/posts/:post_id/comments/:comment_id")
      m.interpolate_path_with_arguments(["foo", "bar"]).should == "/posts/foo/comments/bar"
    end
  end
end