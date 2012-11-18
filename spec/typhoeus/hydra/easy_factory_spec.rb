require 'spec_helper'

describe Typhoeus::Hydra::EasyFactory do
  let(:url) { "http://localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 0) }
  let(:headers) { {} }
  let(:request) { Typhoeus::Request.new(url, :headers => headers) }

  describe "#set_callback" do
    let(:easy_factory) { described_class.new(request, hydra) }

    it "sets easy.on_complete callback" do
      easy_factory.easy.should_receive(:on_complete)
      easy_factory.send(:set_callback)
    end

    it "finishes request" do
      easy_factory.send(:set_callback)
      request.should_receive(:finish)
      easy_factory.easy.complete
    end

    it "resets easy" do
      easy_factory.send(:set_callback)
      easy_factory.easy.should_receive(:reset)
      easy_factory.easy.complete
    end

    it "pushes easy back into the pool" do
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
      expect(easy_factory.hydra.easy_pool).to include(easy_factory.easy)
    end

    it "adds next request" do
      easy_factory.hydra.instance_variable_set(:@queued_requests, [request])
      easy_factory.hydra.should_receive(:add).with(request)
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
    end
  end
end
