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

  describe "#fire_and_forget" do
    it
  end

  context "mocking and stubbing" do
    it
  end

  context "caching and memoization" do
    it
  end
end
