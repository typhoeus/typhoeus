require 'spec_helper'

describe Typhoeus::Hydra::Memoizable do
  let(:base_url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(base_url) }

  describe "add" do
    context "when memoization activated" do
      before { Typhoeus::Config.memoize = true }

      context "when request new" do
        it "sets no response" do
          hydra.add(request)
          expect(request.response).to be_nil
        end

        it "doesn't call complete" do
          request.should_receive(:complete).never
          hydra.add(request)
        end
      end

      context "when request in memory" do
        let(:response) { Typhoeus::Response.new }
        before { hydra.memory[request] = response }

        it "finishes request" do
          request.should_receive(:finish).with(response, true)
          hydra.add(request)
        end

        context "when queued request" do
          let(:queued_request) { Typhoeus::Request.new(base_url) }

          it "dequeues" do
            hydra.queue(queued_request)
            request.should_receive(:finish).with(response, true)
            queued_request.should_receive(:finish).with(response, true)
            hydra.add(request)
          end
        end
      end
    end
  end

  describe "#run" do
    it "clears memory before starting" do
      hydra.memory.should_receive(:clear)
      hydra.run
    end
  end
end
