require 'spec_helper'

describe Typhoeus::Hydra::Queueable do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#queue" do
    let(:request) { Typhoeus::Request.new("") }

    it "accepts requests" do
      hydra.queue(request)
    end

    it "sets hydra on request" do
      hydra.queue(request)
      expect(request.hydra).to eq(hydra)
    end

    it "adds to queued requests" do
      hydra.queue(request)
      expect(hydra.queued_requests).to include(request)
    end
    
    it "adds to front of queued requests" do 
      hydra.queue_front(request)
      expect(hydra.queued_requests.first).to be(request)
    end
  end

  describe "#abort" do
    before { hydra.queued_requests << 1 }

    it "clears queue" do
      hydra.abort
      expect(hydra.queued_requests).to be_empty
    end
  end
end
