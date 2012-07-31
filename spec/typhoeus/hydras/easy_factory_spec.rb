require 'spec_helper'

describe Typhoeus::Hydras::EasyFactory do
  let(:url) { "http://localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 0) }
  let(:headers) { {} }
  let(:request) { Typhoeus::Request.new(url, :headers => headers) }

  describe "#set_callback" do
    let(:easy_factory) { described_class.new(request, hydra) }

    it "sets easy.on_complete callback" do
      easy_factory.easy.should_receive(:on_complete)
      easy_factory.set_callback
    end

    it "sets response on request" do
      easy_factory.set_callback
      easy_factory.easy.complete
      request.response.should be
    end

    it "resets easy" do
      easy_factory.set_callback
      easy_factory.easy.should_receive(:reset)
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
      callback = mock(:call)
      callback.should_receive(:call)
      request.instance_variable_set(:@on_complete, [callback])
      easy_factory.set_callback
      easy_factory.easy.complete
    end
  end
end
