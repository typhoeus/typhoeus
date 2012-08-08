require 'spec_helper'

describe Typhoeus::Hydras::Stubable do
  let(:url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(url) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus.stub(url).and_return(response) }
  after { Typhoeus::Expectation.clear }

  describe "#queue" do
    it "checks expactations" do
      hydra.queue(request)
    end

    context "when expectation found" do
      it "assigns response" do
        hydra.queue(request)
        expect(request.response).to be(response)
      end

      it "executes callbacks" do
        request.should_receive(:execute_callbacks)
        hydra.queue(request)
      end
    end
  end
end
