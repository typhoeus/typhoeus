require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::Request do
  describe "#params_string" do
    it "should dump a sorted string" do
      request = Typhoeus::Request.new(
        "http://google.com",
        :params => {
          'b' => 'fdsa',
          'a' => 'jlk',
          'c' => '789'
        }
      )

      request.params_string.should == "a=jlk&b=fdsa&c=789"
    end

    it "should accept symboled keys" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :b => 'fdsa',
                                        :a => 'jlk',
                                        :c => '789'
                                      })
      request.params_string.should == "a=jlk&b=fdsa&c=789"
    end
  end

  describe "quick request methods" do
    it "can run a GET synchronously" do
      response = Typhoeus::Request.get("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      response.code.should == 200
      JSON.parse(response.body)["REQUEST_METHOD"].should == "GET"
    end

    it "can run a POST synchronously" do
      response = Typhoeus::Request.post("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      response.code.should == 200
      json = JSON.parse(response.body)
      json["REQUEST_METHOD"].should == "POST"
      json["rack.request.query_hash"]["q"].should == "hi"
    end

    it "can run a PUT synchronously" do
      response = Typhoeus::Request.put("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      response.code.should == 200
      JSON.parse(response.body)["REQUEST_METHOD"].should == "PUT"
    end

    it "can run a DELETE synchronously" do
      response = Typhoeus::Request.delete("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      response.code.should == 200
      JSON.parse(response.body)["REQUEST_METHOD"].should == "DELETE"
    end
  end

  it "takes url as the first argument" do
    Typhoeus::Request.new("http://localhost:3000").url.should == "http://localhost:3000"
  end

  it "should parse the host from the url" do
    Typhoeus::Request.new("http://localhost:3000/whatever?hi=foo").host.should == "http://localhost:3000"
    Typhoeus::Request.new("http://localhost:3000?hi=foo").host.should == "http://localhost:3000"
    Typhoeus::Request.new("http://localhost:3000").host.should == "http://localhost:3000"
  end

  it "takes method as an option" do
    Typhoeus::Request.new("http://localhost:3000", :method => :get).method.should == :get
  end

  it "takes headers as an option" do
    headers = {:foo => :bar}
    request = Typhoeus::Request.new("http://localhost:3000", :headers => headers)
    request.headers.should == headers
  end

  it "takes params as an option and adds them to the url" do
    Typhoeus::Request.new("http://localhost:3000", :params => {:foo => "bar"}).url.should == "http://localhost:3000?foo=bar"
  end

  it "takes request body as an option" do
    Typhoeus::Request.new("http://localhost:3000", :body => "whatever").body.should == "whatever"
  end

  it "takes timeout as an option" do
    Typhoeus::Request.new("http://localhost:3000", :timeout => 10).timeout.should == 10
  end

  it "takes cache_timeout as an option" do
    Typhoeus::Request.new("http://localhost:3000", :cache_timeout => 60).cache_timeout.should == 60
  end

  it "takes follow_location as an option" do
    Typhoeus::Request.new("http://localhost:3000", :follow_location => true).follow_location.should == true
  end

  it "takes max_redirects as an option" do
    Typhoeus::Request.new("http://localhost:3000", :max_redirects => 10).max_redirects.should == 10
  end

  it "has the associated response object" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.response = :foo
    request.response.should == :foo
  end

  it "has an on_complete handler that is called when the request is completed" do
    request = Typhoeus::Request.new("http://localhost:3000")
    foo = nil
    request.on_complete do |response|
      foo = response
    end
    request.response = :bar
    request.call_handlers
    foo.should == :bar
  end

  it "has an on_complete setter" do
    foo = nil
    proc = Proc.new {|response| foo = response}
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete = proc
    request.response = :bar
    request.call_handlers
    foo.should == :bar
  end

  it "stores the handled response that is the return value from the on_complete block" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete do |response|
      "handled"
    end
    request.response = :bar
    request.call_handlers
    request.handled_response.should == "handled"
  end

  it "has an after_complete handler that recieves what on_complete returns" do
    request = Typhoeus::Request.new("http://localhost:3000")
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

  it "has an after_complete setter" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete do |response|
      "handled"
    end
    good = nil
    proc = Proc.new {|object| good = object == "handled"}
    request.after_complete = proc

    request.call_handlers
    good.should be_true
  end

  describe "retry" do
    it "should take a retry option"
    it "should count the number of times a request has failed"
  end

end
