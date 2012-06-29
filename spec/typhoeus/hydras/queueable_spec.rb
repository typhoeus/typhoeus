require 'spec_helper'

describe Typhoeus::Hydras::Queueable do
  let(:url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#queue" do
    let(:request) { Typhoeus::Request.new("") }

    it "accepts requests" do
      hydra.queue(request)
    end

    it "sets hydra on request" do
      hydra.queue(request)
      request.hydra.should eq(hydra)
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

  describe "#abort" do
    before { hydra.queued_requests << 1 }

    it "clears queue" do
      hydra.abort
      hydra.queued_requests.should be_empty
    end
  end
end
