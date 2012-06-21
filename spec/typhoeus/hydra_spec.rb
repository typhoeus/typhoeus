require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe ".hydra" do
    it "returns a hydra" do
      Typhoeus::Hydra.hydra.should be_a(Typhoeus::Hydra)
    end
  end

  describe ".hydra=" do
    after { Typhoeus::Hydra.hydra = Typhoeus::Hydra.new }

    it "sets hydra" do
      Typhoeus::Hydra.hydra = :foo
      Typhoeus::Hydra.hydra.should eq(:foo)
    end
  end

  describe "#queue" do
    let(:request) { Typhoeus::Request.new("") }

    it "accepts requests" do
      hydra.queue(request)
    end

    context "when max concurrency limit not reached" do
      let(:options) { { :max_concurrency => 10 } }

      it "adds to multi" do
        hydra.multi.expects(:add)
        hydra.queue(request)
      end
    end

    context "when max concurrency limit reached" do
      let(:options) { { :max_concurrency => 0 } }

      it "doesn't add to multi" do
        hydra.multi.expects(:add).never
        hydra.queue(request)
      end

      it "adds to queued requests" do
        hydra.queue(request)
        hydra.queued_requests.should include(request)
      end
    end
  end

  describe "#get_easy_object" do
    let(:headers) { {} }
    let(:request) { Typhoeus::Request.new("fubar", :headers => headers) }
    let(:hydra) { Typhoeus::Hydra.hydra }
    let(:easy) { hydra.method(:get_easy_object).call(request) }

    context "when header with user agent" do
      let(:headers) { {'User-Agent' => "Custom"} }

      it "doesn't modify user agent" do
        easy.headers['User-Agent'].should eq("Custom")
      end
    end

    context "when header without user agent" do
      it "add user agent" do
        easy.headers['User-Agent'].should eq(Typhoeus::USER_AGENT)
      end
    end

    context "when params are supplied"  do
      [:post, :put, :delete, :head, :patch, :options, :trace, :connect].each do |method|
        it "should not delete the params if the request is a #{method.to_s.upcase}" do
          request = Typhoeus::Request.new("fubar", :method => method, :params => {:coffee => 'black'})
          hydra.send(:get_easy_object, request).params.should == {:coffee => 'black'}
        end
      end
    end

    describe "the body of the request" do
      [:post, :put, :delete, :head, :patch, :options, :trace, :connect].each do |method|
        it "should not remove the body of the request, when the request is a #{method.to_s.upcase}" do
          request = Typhoeus::Request.new("fubar", :method => method, :body => "kill the body and you kill the head")
          hydra.send(:get_easy_object, request).request_body.should == "kill the body and you kill the head"
        end
      end
    end
  end

  describe "#run" do
    before do
      requests.each { |r| hydra.queue r }
    end

    context "when no request queued" do
      let(:requests) { [] }

      it "does nothing" do
        hydra.multi.expects(:perform)
        hydra.run
      end
    end

    context "when request queued" do
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:requests) { [first] }

      it "runs multi#perform" do
        hydra.multi.expects(:perform)
        hydra.run
      end

      it "sends" do
        hydra.run
        first.response.should be
      end
    end

    context "when three request queued" do
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:second) { Typhoeus::Request.new("localhost:3001/second") }
      let(:third) { Typhoeus::Request.new("localhost:3001/third") }
      let(:requests) { [first, second, third] }

      it "runs multi#perform" do
        hydra.multi.expects(:perform)
        hydra.run
      end

      it "sends first" do
        hydra.run
        first.response.should be
      end

      it "sends second" do
        hydra.run
        second.response.should be
      end

      it "sends third" do
        hydra.run
        third.response.should be
      end

      it "sends first first" do
        first.on_complete do
          second.response.should be_nil
          third.response.should be_nil
        end
      end

      it "sends second second" do
        first.on_complete do
          first.response.should be
          third.response.should be_nil
        end
      end

      it "sends thirds last" do
        first.on_complete do
          second.response.should be
          third.response.should be
        end
      end
    end

    context "when really queued request" do
      let(:options) { {:max_concurrency => 1} }
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:second) { Typhoeus::Request.new("localhost:3001/second") }
      let(:third) { Typhoeus::Request.new("localhost:3001/third") }
      let(:requests) { [first, second, third] }

      it "sends first" do
        hydra.run
        first.response.should be
      end

      it "sends second" do
        hydra.run
        second.response.should be
      end

      it "sends third" do
        hydra.run
        third.response.should be
      end
    end
  end

  describe "#set_callback" do
    let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 0) }
    let(:easy) { Ethon::Easy.new }
    let(:request) { Typhoeus::Request.new(url) }
    let(:set_callback) { hydra.send(:set_callback, easy, request) }

    it "sets easy.on_complete callback" do
      easy.expects(:on_complete)
      set_callback
    end

    it "sets response on request" do
      set_callback
      easy.complete
      request.response.should be
    end

    it "resets easy" do
      set_callback
      easy.expects(:reset)
      easy.complete
    end

    it "pushes easy back into the pool" do
      set_callback
      easy.complete
      hydra.easy_pool.should include(easy)
    end

    it "queues next request" do
      hydra.instance_variable_set(:@queued_requests, [request])
      set_callback
      easy.complete
      hydra.queued_requests.should include(request)
    end

    it "runs requests complete callback" do
      request.instance_variable_set(:@on_complete, mock(:call))
      set_callback
      easy.complete
    end
  end

  describe "#fire_and_forget" do
    it
  end

  context "mocking and stubbing" do
    it
  end

  context "caching" do
    it
  end
end
