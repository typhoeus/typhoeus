require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Request do
  describe "#inspect" do
    before(:each) do
      @request = Typhoeus::Request.new('http://www.google.com/',
                                       :body => "a=1&b=2",
                                       :params => { :c => 'ok' },
                                       :method => :get,
                                       :headers => { 'Content-Type' => 'text/html' })
    end

    it "should dump out the URI" do
      @request.inspect.should =~ /http:\/\/www\.google\.com/
    end

    it "should dump out the body" do
      @request.inspect.should =~ /a=1&b=2/
    end

    it "should dump params" do
      @request.inspect.should =~ /:c\s*=>\s*"ok"/
    end

    it "should dump the method" do
      @request.inspect.should =~ /:get/
    end

    it "should dump out headers" do
      @request.inspect.should =~ /"Content-Type"\s*=>\s*"text\/html"/
    end
  end

  context "marshalling" do

    let(:request) do
      Typhoeus::Request.new("http://google.com")
    end

    describe "#marshal_dump" do
      context "when an on_complete handler is defined" do

        before do
          request.on_complete {}
        end

        it "does not raise an error" do
          lambda { Marshal.dump(request) }.should_not raise_error(TypeError)
        end

      end

      context "when an after_complete handler is defined" do

        before do
          request.after_complete {}
        end

        it "does not raise an error" do
          lambda { Marshal.dump(request) }.should_not raise_error(TypeError)
        end

      end

    end

    it "is reversible but exclude handlers" do
      request.on_complete {}
      request.after_complete {}

      new_request = Marshal.load(Marshal.dump(request))

      new_request.url.should == request.url
      new_request.on_complete.should be_nil
      new_request.after_complete.should be_nil
    end

  end

  describe "#localhost?" do
    %w(localhost 127.0.0.1 0.0.0.0).each do |host|
      it "should be true for the #{host} host" do
        req = Typhoeus::Request.new("http://#{host}")
        req.should be_localhost
      end
    end

    it "should be false for other domains" do
      req = Typhoeus::Request.new("http://google.com")
      req.should_not be_localhost
    end
  end

  describe "#user_agent=" do
    it "should set the user agent header and emit a deprecation warning" do
      $stderr.should_receive(:puts).with(/DEPRECATED:/)
      req = Typhoeus::Request.new("http://google.com")
      req.user_agent = "foobar agent"
      req.user_agent.should == "foobar agent"
    end
  end

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

    it "should translate params with values that are arrays to the proper format" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => ['789','2434']
                                      })
      request.params_string.should == "a=789&a=2434"
    end

    it "should allow the newer bracket notation for array params" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        "a[]" => ['789','2434']
                                      })
      request.params_string.should == "a%5B%5D=789&a%5B%5D=2434"
    end

    it "should nest arrays in hashes" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => { :b => { :c => ['d','e'] } }
                                      })
      request.params_string.should == "a%5Bb%5D%5Bc%5D=d&a%5Bb%5D%5Bc%5D=e"
    end

    it "should translate nested params correctly" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => { :b => { :c => 'd' } }
                                      })
      request.params_string.should == "a%5Bb%5D%5Bc%5D=d"
    end
  end

  describe "quick request methods" do
    it "can run a GET synchronously" do
      response = Typhoeus::Request.get("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      response.code.should == 200
      JSON.parse(response.body)["REQUEST_METHOD"].should == "GET"
    end

    it "can run a POST synchronously" do
      response = Typhoeus::Request.post("http://localhost:3000", :params => {:q => { :a => "hi" } }, :headers => {:foo => "bar"})
      response.code.should == 200

      json = JSON.parse(response.body)
      json["REQUEST_METHOD"].should == "POST"
      json["rack.request.form_hash"]["q"]["a"].should == "hi"
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

  it "accepts a string for the timeout option" do
    Typhoeus::Request.new("http://localhost:3000", :timeout => "150").timeout.should == 150
  end

  it "doesn't convert a nil timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :timeout => nil).timeout.should_not == nil.to_i
  end

  it "doesn't convert an empty timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :timeout => "").timeout.should_not == "".to_i
  end

  it "takes connect_timeout as an option" do
    Typhoeus::Request.new("http://localhost:3000", :connect_timeout => 14).connect_timeout.should == 14
  end

  it "accepts a string for the connect_timeout option" do
    Typhoeus::Request.new("http://localhost:3000", :connect_timeout => "420").connect_timeout.should == 420
  end

  it "doesn't convert a nil connect_timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :connect_timeout => nil).connect_timeout.should_not == nil.to_i
  end

  it "doesn't convert an empty connect_timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :connect_timeout => "").connect_timeout.should_not == "".to_i
  end

  it "takes cache_timeout as an option" do
    Typhoeus::Request.new("http://localhost:3000", :cache_timeout => 60).cache_timeout.should == 60
  end

  it "accepts a string for the cache_timeout option" do
    Typhoeus::Request.new("http://localhost:3000", :cache_timeout => "42").cache_timeout.should == 42
  end

  it "doesn't convert a nil cache_timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :cache_timeout => nil).cache_timeout.should_not == nil.to_i
  end

  it "doesn't convert an empty cache_timeout to an integer" do
    Typhoeus::Request.new("http://localhost:3000", :cache_timeout => "").cache_timeout.should_not == "".to_i
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

  describe "time info" do
    it "should have time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      response.time.should > 0
    end

    it "should have connect time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      response.connect_time.should > 0
    end

    it "should have app connect time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      response.app_connect_time.should  > 0
    end

    it "should have start transfer time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      response.start_transfer_time.should  > 0
    end

    it "should have pre-transfer time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      response.pretransfer_time.should  > 0
    end

  end


  describe "authentication" do

    it "should allow to set username and password" do
      auth = { :username => 'foo', :password => 'bar' }
      e = Typhoeus::Request.get(
        "http://localhost:3001/auth_basic/#{auth[:username]}/#{auth[:password]}",
        auth
      )
      e.code.should == 200
    end

    it "should allow to set authentication method" do
      auth = {
        :username => 'username',
        :password => 'password',
        :auth_method => :ntlm
      }
      e = Typhoeus::Request.get(
        "http://localhost:3001/auth_ntlm",
        auth
      )
      e.code.should == 200
    end

  end

  describe "retry" do
    it "should take a retry option"
    it "should count the number of times a request has failed"
  end

end
