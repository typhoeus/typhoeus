require 'spec_helper'

describe Typhoeus::Hydras::EasyFactory do
  let(:url) { "http://localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 0) }
  let(:headers) { {} }
  let(:request) { Typhoeus::Request.new(url, :headers => headers) }

  describe "#get" do
    let(:headers) { {} }
    let(:easy) { described_class.new(request, hydra).get }

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
  end

  describe "#set_callback" do
    let(:easy_factory) { described_class.new(request, hydra) }

    it "sets easy.on_complete callback" do
      easy_factory.easy.expects(:on_complete)
      easy_factory.set_callback
    end

    it "sets response on request" do
      easy_factory.set_callback
      easy_factory.easy.complete
      request.response.should be
    end

    it "resets easy" do
      easy_factory.set_callback
      easy_factory.easy.expects(:reset)
      easy_factory.easy.complete
    end

    it "pushes easy back into the pool" do
      easy_factory.set_callback
      easy_factory.easy.complete
      easy_factory.hydra.easy_pool.should include(easy_factory.easy)
    end

    it "queues next request" do
      easy_factory.hydra.instance_variable_set(:@queued_requests, [request])
      easy_factory.set_callback
      easy_factory.easy.complete
      easy_factory.hydra.queued_requests.should include(request)
    end

    it "runs requests complete callback" do
      request.instance_variable_set(:@on_complete, mock(:call))
      easy_factory.set_callback
      easy_factory.easy.complete
    end
  end
end
