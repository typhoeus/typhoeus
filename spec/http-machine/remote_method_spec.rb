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
  
  describe "#merge_options" do
    it "should keep the passed in options first" do
      m = HTTPMachine::RemoteMethod.new("User-Agent" => "whatev", :foo => :bar)
      m.merge_options({"User-Agent" => "http-machine"}).should == {"User-Agent" => "http-machine", :foo => :bar}
    end
    
    it "should combine the params" do
      m = HTTPMachine::RemoteMethod.new(:foo => :bar, :params => {:id => :asdf})
      m.merge_options({:params => {:desc => :jkl}}).should == {:foo => :bar, :params => {:id => :asdf, :desc => :jkl}}
    end
  end
  
  describe "caching reponses" do
    before(:each) do
      @m = HTTPMachine::RemoteMethod.new(:cache_response => true)
      @args    = ["foo", "bar"]
      @options = {:asdf => {:jkl => :bar}}
    end
    
    it "should store if a resposne should be cached" do
      @m.cache_response?.should be_true
      @m.options.should == {}
    end
    
    it "should tell when a method is already called" do
      @m.already_called?(@args, @options).should be_false
      @m.calling(@args, @options)
      @m.already_called?(@args, @options).should be_true
      @m.already_called?([], {}).should be_false
    end
    
    it "should call response blocks and clear the cache" do
      response_block_called = mock('response_block')
      response_block_called.should_receive(:call).exactly(1).times
      
      @m.add_response_block(lambda {|res| res.should == :foo; response_block_called.call}, @args, @options)
      @m.calling(@args, @options)
      @m.call_response_blocks(:foo, @args, @options)
      @m.already_called?(@args, @options).should be_false
      @m.call_response_blocks(:asdf, @args, @options) #just to make sure it doesn't actually call that block again
    end
  end
end