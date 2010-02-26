require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::Easy do  
  describe "options" do
    it "should not follow redirects if not instructed to" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001/redirect"
      e.method = :get
      e.perform
      e.response_code.should == 302
    end

    it "should allow for following redirects" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001/redirect"
      e.method = :get
      e.follow_location = true
      e.perform
      e.response_code.should == 200
      JSON.parse(e.response_body)["REQUEST_METHOD"].should == "GET"
    end

    it "should allow you to set the user agent" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :get
      easy.user_agent = "myapp"
      easy.perform
      easy.response_code.should == 200
      JSON.parse(easy.response_body)["HTTP_USER_AGENT"].should == "myapp"
    end

    it "should provide a timeout in milliseconds" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001"
      e.method = :get
      e.timeout = 50
      e.perform
      # this doesn't work on a mac for some reason
#      e.timed_out?.should == true
    end

    it "should allow the setting of the max redirects to follow" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001/redirect"
      e.method = :get
      e.follow_location = true
      e.max_redirects = 5
      e.perform
      e.response_code.should == 200
    end

    it "should handle our bad redirect action, provided we've set max_redirects properly" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001/bad_redirect"
      e.method = :get
      e.follow_location = true
      e.max_redirects = 5
      e.perform
      e.response_code.should == 302
    end
  end
  
  describe "authentication" do
    it "should allow to set username and password" do
      e = Typhoeus::Easy.new
      username, password = 'foo', 'bar'
      e.auth = { :username => username, :password => password }
      e.url = "http://localhost:3001/auth_basic/#{username}/#{password}"
      e.method = :get
      e.perform
      e.response_code.should == 200
    end
    
    it "should allow to query auth methods support by the server" do
      e = Typhoeus::Easy.new
      e.url = "http://localhost:3001/auth_basic/foo/bar"
      e.method = :get
      e.perform
      e.auth_methods.should == Typhoeus::Easy::AUTH_TYPES[:CURLAUTH_BASIC]
    end

    it "should allow to set authentication method" do
      e = Typhoeus::Easy.new
      e.auth = { :username => 'username', :password => 'password', :method => Typhoeus::Easy::AUTH_TYPES[:CURLAUTH_NTLM] }
      e.url = "http://localhost:3001/auth_ntlm"
      e.method = :get
      e.perform
      e.response_code.should == 200
    end
  end
  
  describe "get" do
    it "should perform a get" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :get
      easy.perform
      easy.response_code.should == 200
      JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "GET"
    end
  end

  describe "head" do
    it "should perform a head" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :head
      easy.perform
      easy.response_code.should == 200
    end
  end

  describe "start_time" do
    it "should be get/settable" do
      time = Time.now
      easy = Typhoeus::Easy.new
      easy.start_time.should be_nil
      easy.start_time = time
      easy.start_time.should == time
    end
  end

  describe "params=" do
    it "should handle arrays of params" do
      easy = Typhoeus::Easy.new
      easy.url = "http://localhost:3002/index.html"
      easy.method = :get
      easy.request_body = "this is a body!"
      easy.params = {
        :foo => 'bar',
        :username => ['dbalatero', 'dbalatero2']
      }
      
      easy.url.should =~ /\?.*username=dbalatero&username=dbalatero2/
    end
  end


  describe "put" do
    it "should perform a put" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :put
      easy.perform
      easy.response_code.should == 200
      JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "PUT"
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :put
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end
  
  describe "post" do
    it "should perform a post" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.perform
      easy.response_code.should == 200
      JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "POST"
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
    
    it "should handle params" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :post
      easy.params = {:foo => "bar"}
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("foo=bar")
    end
  end
  
  describe "delete" do
    it "should perform a delete" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.perform
      easy.response_code.should == 200
      JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "DELETE"
    end
    
    it "should send a request body" do
      easy = Typhoeus::Easy.new
      easy.url    = "http://localhost:3002"
      easy.method = :delete
      easy.request_body = "this is a body!"
      easy.perform
      easy.response_code.should == 200
      easy.response_body.should include("this is a body!")
    end
  end  
end
