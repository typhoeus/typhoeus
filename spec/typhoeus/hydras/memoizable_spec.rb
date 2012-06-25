require 'spec_helper'

describe Typhoeus::Hydras::Memoizable do
  let(:url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(url, {:method => :get}) }

  describe "queue" do
    context "when memoization activated" do
      before { Typhoeus::Config.memoize = true }
      after { Typhoeus::Config.memoize = false }

      context "when request new" do
        it "sets no response" do
          hydra.queue(request)
          request.response.should be_nil
        end

        it "doesn't call complete" do
          request.expects(:complete).never
          hydra.queue(request)
        end
      end

      context "when request in memory" do
        let(:response) { Typhoeus::Response.new }
        before { hydra.memory[request] = response }

        it "sets response" do
          hydra.queue(request)
          request.response.should be
        end

        it "sets response via instance_variable_set to avoid short circuit" do
          request.expects(:instance_variable_set).with(:@response, response)
          hydra.queue(request)
        end

        it "calls complete" do
          request.expects(:complete)
          hydra.queue(request)
        end
      end
    end
  end
end
