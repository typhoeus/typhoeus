require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus do
  before(:each) do
    @klass = Class.new do
      include Typhoeus
    end
  end
  
  before(:all) do
    @pid = start_method_server(3001)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end

  describe "get" do
    it "should add a get method" do
      easy = @klass.get("http://localhost:3001/posts.xml")
      easy.response_code.should == 200
      easy.response_body.should include("REQUEST_METHOD=GET")
      easy.response_body.should include("REQUEST_URI=/posts.xml")
    end

    it "should take passed in params and add them to the query string" do
      easy = @klass.get("http://localhost:3001", {:params => {:foo => :bar}})
      easy.response_body.should include("QUERY_STRING=foo=bar")
    end
  end # get
  
  describe "post" do
    it "should add a post method" do
      easy = @klass.post("http://localhost:3001/posts.xml", {:params => {:post => {:author => "paul", :title => "a title", :body => "a body"}}})
      easy.response_code.should == 200
      easy.response_body.should include("post%5Bbody%5D=a+body")
      easy.response_body.should include("post%5Bauthor%5D=paul")
      easy.response_body.should include("post%5Btitle%5D=a+title")
      easy.response_body.should include("REQUEST_METHOD=POST")
    end

    it "should add a body" do
      easy = @klass.post("http://localhost:3001/posts.xml", {:body => "this is a request body"})
      easy.response_code.should == 200
      easy.response_body.should include("this is a request body")
      easy.response_body.should include("REQUEST_METHOD=POST")
    end
  end # post
  
  it "should add a put method" do
    easy = @klass.put("http://localhost:3001/posts/3.xml")
    easy.response_code.should == 200
    easy.response_body.should include("REQUEST_METHOD=PUT")
  end
  
  it "should add a delete method" do
    easy = @klass.delete("http://localhost:3001/posts/3.xml")
    easy.response_code.should == 200
    easy.response_body.should include("REQUEST_METHOD=DELETE")
  end
  
  describe "after_filter" do
    it "should call an after filter then call the regular block" do
      filter_mock = mock("filter_called")
      filter_mock.should_receive(:call)

      klass = Class.new do
        include Typhoeus
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
        include Typhoeus
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
      
      it "should use a path passed into the remote method call" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://pauldix.net"
        end
        
        @klass.should_receive(:get).with("http://pauldix.net/whatev?asdf=foo", {})
        @klass.do_stuff(:path => "/whatev?asdf=foo")
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
      it "should take :on_success as an argument" do
        success_called = mock("success")
        success_called.should_receive(:call)
        
        @klass.instance_eval do
          @success_called = success_called
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :on_success => :handle_response
          
          def self.handle_response(easy)
            @success_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should use default_on_success if no on_success provided" do
        success_called = mock("success")
        success_called.should_receive(:call)
        
        @klass.instance_eval do
          @success_called = success_called
          default_on_success :handle_it
          remote_method :do_stuff, :base_uri => "http://localhost:3001"
          
          def self.handle_it(easy)
            @success_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should override default_on_success if on_success is provided" do
        success_called = mock("success")
        success_called.should_receive(:call)
        
        @klass.instance_eval do
          @success_called = success_called
          default_on_success :should_not_get_called
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :on_success => :handle_it
          
          def self.handle_it(easy)
            @success_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should give the returned value from the on_success handler to the block" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :on_success => :handle_response
          
          def self.handle_response(easy)
            :foo
          end
        end

        stuff = nil
        @klass.do_stuff do |val|
          stuff = val
        end
        
        stuff.should == :foo
      end
    end
    
    describe "on_failure" do
      it "should take :on_failure as an argument" do
        failure_called = mock("failure")
        failure_called.should_receive(:call)
        
        @klass.instance_eval do
          @failure_called = failure_called
          remote_method :do_stuff, :base_uri => "http://localhost:9999", :on_failure => :handle_response
          
          def self.handle_response(easy)
            @failure_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should use default_on_failure if no on_success provided" do
        failure_called = mock("failure")
        failure_called.should_receive(:call)
        
        @klass.instance_eval do
          @failure_called = failure_called
          default_on_failure :handle_response
          remote_method :do_stuff, :base_uri => "http://localhost:9999"
          
          def self.handle_response(easy)
            @failure_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should override default_on_failure if no method is provided" do
        failure_called = mock("failure")
        failure_called.should_receive(:call)
        
        @klass.instance_eval do
          @failure_called = failure_called
          default_on_failure :should_not_call
          remote_method :do_stuff, :base_uri => "http://localhost:9999", :on_failure => :handle_response
          
          def self.handle_response(easy)
            @failure_called.call
          end
        end
        
        @klass.do_stuff {|e| }
      end
      
      it "should give the returned value from the on_success handler to the block" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://localhost:9999", :on_failure => :handle_response
          
          def self.handle_response(easy)
            :foo
          end
        end
        
        stuff = nil
        @klass.do_stuff {|val| stuff = val}
        stuff.should == :foo
      end
    end
    
    describe "params" do
      it "should take :params as an argument" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :params => {:foo => :bar}
        end

        response_body = nil
        @klass.do_stuff {|e| response_body = e.response_body}
        response_body.should include("QUERY_STRING=foo=bar")
      end
      
      it "should add :params from remote method definition with params passed in when called" do
        @klass.instance_eval do
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :params => {:foo => :bar}
        end

        response_body = nil
        @klass.do_stuff(:params => {:asdf => :jkl}) {|e| response_body = e.response_body}
        response_body.should include("QUERY_STRING=foo=bar&asdf=jkl")
      end
    end
    
    describe "memoize_responses" do
      it "should only make one call to the http method and the on_success handler if :memoize_responses => true" do
        success_mock = mock("success")
        success_mock.should_receive(:call).exactly(2).times
        
        @klass.instance_eval do
          @success_mock = success_mock
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :path => "/:file", :memoize_responses => true, :on_success => :success
          
          def self.success(easy)
            @success_mock.call
            :foo
          end
        end
        
#        @klass.should_receive(:get).exactly(2).times.and_return(mock("easy"))
        first_return_val  = nil
        second_return_val = nil
        third_return_val  = nil
        
        Typhoeus.service_access do
          @klass.do_stuff("user.html") do |val|
            first_return_val = val
          end
          
          
          @klass.do_stuff("post.html") do |val|
            second_return_val = val
          end
          
          @klass.do_stuff("user.html") do |val|
            third_return_val = val
          end
        end
        
        first_return_val.should  == :foo
        second_return_val.should == :foo
        third_return_val.should  == :foo
      end
    end
    
    describe "cache_response" do
      before(:each) do
        success_mock = mock("success")
        success_mock.should_receive(:call).exactly(1).times
        require 'memcached'
        @klass.cache_server = Memcached.new("localhost:11211")
        @klass.instance_eval do
          @success_mock = success_mock
          remote_method :do_stuff, :base_uri => "http://localhost:3001", :path => "/:file", :cache_responses => true, :on_success => :success
          
          def self.success(easy)
            @success_mock.call
            :foo
          end
        end
      end
      
      it "should pull from the cache if :cache_response => true" do        
        first_return_val  = nil
        second_return_val = nil

        Typhoeus.service_access do
          @klass.do_stuff("user.html") {|val| first_return_val = val}
        end
        
        Typhoeus.service_access do
          @klass.do_stuff("user.html") {|val| second_return_val = val}
        end
        
        first_return_val.should  == :foo
        second_return_val.should == :foo        
      end
      
      it "should only hit the cache once for the same value" do
        cache = Memcached.new("localhost:11211")
        @klass.cache_server = cache
        
        Typhoeus.service_access do
          @klass.do_stuff("asdf.html") {|val| }
        end
        
        first_return_val = nil
        second_return_val = nil
        cache.should_receive(:get).exactly(1).times.and_return(:foo)
        Typhoeus.service_access do
          @klass.do_stuff("asdf.html") {|val| first_return_val = val}
          @klass.do_stuff("asdf.html") {|val| second_return_val = val}
        end
        
        first_return_val.should  == :foo
        second_return_val.should == :foo        
      end
      
      it "should only hit the cache once if there is a cache miss (don't check again and again inside the same block)." do
        first_return_val  = nil
        second_return_val = nil

        cache = Memcached.new("localhost:11211")
        cache.should_receive(:get).exactly(1).times
        @klass.cache_server = cache
        Typhoeus.service_access do
          @klass.do_stuff("foo.html") {|val| first_return_val = val}
          @klass.do_stuff("foo.html") {|val| second_return_val = val}
        end
        
        first_return_val.should  == :foo
        second_return_val.should == :foo        
      end
      
      it "should store an object in the cache with a set ttl"
      it "should take a hash with get and set method pointers to enable custom caching behavior"
    end
  end # remote_method
  
  describe "cache_server" do
    it "should store a cache_server" do
      @klass.cache_server = :foo
    end
  end
  
  describe "get_memcache_resposne_key" do
    it "should return a key that is an and of the method name, args, and options" do
      @klass.get_memcache_response_key(:do_stuff, ["foo"], {}).should == "2edc0bf05e3f232d4012b1d3ddde4e35588742f4195911acedfe357488e6eeca"
    end
  end
  
  # describe "multiple with post" do
  #   require 'rubygems'
  #   require 'json'
  #   it "shoudl do stuff" do
  #     @klass.instance_eval do
  #       remote_method :post_stuff, :path => "/entries/metas/:meta_id/ids", :base_uri => "http://localhost:4567", :method => :post
  #       remote_method :get_stuff, :base_uri => "http://localhost:4567"
  #     end
  #     
  #     Typhoeus.service_access do
  #       @klass.post_stuff("paul-tv", :body => ["foo", "bar"].to_json) {|e| }
  #       @klass.get_stuff {|e| }
  #     end
  #   end
  # end
end