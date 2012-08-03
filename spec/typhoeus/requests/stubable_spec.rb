require 'spec_helper'

describe Typhoeus::Requests::Stubable do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus.stub(url).and_return(response) }
  after { Typhoeus.expectations.clear }

  describe "#queue" do
    it "checks expactations" do
      request.run
    end

    context "when expectation found" do
      it "assigns response" do
        request.run
        expect(request.response).to be(response)
      end

      it "executes callbacks" do
        request.should_receive(:complete)
        request.run
      end
    end
  end
end
