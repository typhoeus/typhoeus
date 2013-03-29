require 'spec_helper'

describe Typhoeus::Request::Stubbable do
  let(:base_url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(base_url) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus.stub(base_url).and_return(response) }

  describe "#run" do
    it "checks expectations" do
      request.run
    end

    context "when expectation found" do
      it "finishes request" do
        request.should_receive(:finish)
        request.run
      end

      it "sets mock on response" do
        request.run
        expect(request.response.mock).to be(true)
      end
    end
  end
end
