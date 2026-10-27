# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Hydra do
  let(:base_url) { TestServer.host }
  let(:request) { Typhoeus::Request.new(base_url) }
  let(:response) { Typhoeus::Response.new }
  let(:hydra) { Typhoeus::Hydra.new }

  before { Typhoeus.stub(base_url).and_return(response) }

  describe "#add" do
    it "does not add a stubbed request to the multi" do
      hydra.add(request)

      expect(hydra.multi.easy_handles).to be_empty
      expect(request.response).to be(response)
    end

    context "when expectation found" do
      it "calls on_headers callbacks" do
        canary = :not_called
        request.on_headers do
          canary = :called
        end
        hydra.add(request)
        hydra.run
        expect(canary).to eq(:called)
      end

      it "calls on_body callbacks" do
        canary = :not_called
        request.on_body do
          canary = :called
        end
        hydra.add(request)
        hydra.run
        expect(canary).to eq(:called)
      end

      it "finishes response" do
        expect(request).to receive(:finish)
        hydra.add(request)
      end

      it "is a mock" do
        hydra.add(request)
        expect(request.response.mock).to be(true)
      end
    end
  end
end
