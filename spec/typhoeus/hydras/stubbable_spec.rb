require 'spec_helper'

describe Typhoeus::Hydras::Stubbable do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }
  let(:response) { Typhoeus::Response.new }
  let(:hydra) { Typhoeus::Hydra.new }

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

      it "sets mock on response" do
        hydra.queue(request)
        expect(request.response.mock).to be(true)
      end
    end
  end
end
