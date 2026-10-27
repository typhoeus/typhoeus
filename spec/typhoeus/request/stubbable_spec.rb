# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request do
  let(:base_url) { TestServer.url }
  let(:request) { Typhoeus::Request.new(base_url) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus.stub(base_url).and_return(response) }

  describe "#run" do
    it "returns the stubbed response" do
      expect(request.run).to be(response)
    end

    context "inside Typhoeus.with_connection" do
      before { Typhoeus::Config.block_connection = true }

      it "returns the real response when the stub forwards to the service" do
        Typhoeus::Expectation.clear
        Typhoeus.stub(base_url) do |stubbed_request|
          Typhoeus.with_connection { stubbed_request.run }
        end

        callback_calls = 0
        request = Typhoeus::Request.new(base_url)
        request.on_complete { callback_calls += 1 }
        real_response = request.run

        expect(real_response.code).to eq(200)
        expect(real_response.mock).to be_falsey
        expect(callback_calls).to eq(1)
      end

      it "performs the request instead of using the stub" do
        real_response = Typhoeus.with_connection { Typhoeus::Request.new(base_url).run }

        expect(real_response).to_not be(response)
        expect(real_response.code).to eq(200)
        expect(real_response.mock).to be_falsey
      end

      it "performs a queued request instead of using the stub" do
        hydra = Typhoeus::Hydra.new
        real_request = Typhoeus::Request.new(base_url)
        hydra.queue(real_request)

        Typhoeus.with_connection { hydra.run }

        expect(real_request.response).to_not be(response)
        expect(real_request.response.code).to eq(200)
      end

      it "uses the stub again afterwards" do
        Typhoeus.with_connection { Typhoeus::Request.new(base_url).run }

        expect(Typhoeus::Request.new(base_url).run).to be(response)
      end

      it "restores stubbing when the block raises" do
        expect {
          Typhoeus.with_connection { raise "boom" }
        }.to raise_error("boom")

        expect(Typhoeus::Request.new(base_url).run).to be(response)
      end
    end

    context "when expectation found" do
      it "calls on_headers callbacks" do
        canary = :not_called
        request.on_headers do
          canary = :called
        end
        request.run
        expect(canary).to eq(:called)
      end

      it "calls on_body callbacks" do
        canary = :not_called
        request.on_body do
          canary = :called
        end
        request.run
        expect(canary).to eq(:called)
      end

      it "finishes request" do
        expect(request).to receive(:finish)
        request.run
      end

      it "sets mock on response" do
        request.run
        expect(request.response.mock).to be(true)
      end
    end
  end
end
