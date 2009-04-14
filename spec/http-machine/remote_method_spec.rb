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
  
  describe "path" do
    it "should pull path out of the options hash" do
      m = HTTPMachine::RemoteMethod.new(:post, :path => "foo")
      m.path.should == "foo"
      m.options.should_not have_key(:path)
    end
    
    it "should output argument names from the symbols in the path" do
      m = HTTPMachine::RemoteMethod.new(:get, :path => "/posts/:post_id/comments/:comment_id")
      m.argument_names.should == ["post_id", "comment_id"]
    end
    
    it "should output an empty string when there are no arguments in path" do
      m = HTTPMachine::RemoteMethod.new(:get, :path => "/default.html")
      m.argument_names.should == []
    end
    
    it "should output and empty string when there is no path specified" do
      m = HTTPMachine::RemoteMethod.new(:get, {})
      m.argument_names.should == []
    end
    
    it "should provide an empty argument_names string if an empty array" do
      m = HTTPMachine::RemoteMethod.new(:get, :path => "/default.html")
      m.argument_names_string.should == ""
    end
    
    it "should provide an argument_names string with a trailing , if one or more arguments" do
      m = HTTPMachine::RemoteMethod.new(:get, :path => "/posts/:post_id/comments/:comment_id")
      m.argument_names_string.should == "post_id, comment_id, "
    end
    
    it "should interpolate a path with arguments" do
      m = HTTPMachine::RemoteMethod.new(:get, :path => "/posts/:post_id/comments/:comment_id")
      m.interpolate_path_with_arguments(["foo", "bar"]).should == "/posts/foo/comments/bar"
    end
  end
end