require 'spec_helper'

describe Typhoeus::Hydra::Cacheable do
  let(:base_url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(base_url, {:method => :get}) }
  let(:response) { Typhoeus::Response.new }
  let(:cache) { MemoryCache.new }

  describe "add" do
    context "when cache activated" do
      before { Typhoeus::Config.cache = cache }
      after { Typhoeus::Config.cache = false }

      context "when request new" do
        it "sets no response" do
          hydra.add(request)
          expect(request.response).to be_nil
        end

        it "doesn't call complete" do
          expect(request).to receive(:complete).never
          hydra.add(request)
        end
      end

      context "when request in memory" do
        before { cache.memory[request] = response }

        it "returns response with cached status" do
          hydra.add(request)
          expect(response.cached?).to be_truthy
        end

        context "when no queued requests" do
          it "finishes request" do
            expect(request).to receive(:finish).with(response)
            hydra.add(request)
            expect(response.cached?).to be_truthy
          end
        end

        context "when queued requests" do
          let(:queued_request) { Typhoeus::Request.new(base_url, {:method => :get}) }

          before { cache.memory[queued_request] = response }

          it "finishes both requests" do
            hydra.queue(queued_request)
            expect(request).to receive(:finish).with(response)
            expect(queued_request).to receive(:finish).with(response)
            hydra.add(request)
          end
        end
      end

      context "when cache is specified on a request" do
        before { Typhoeus::Config.cache = false }

        context "when cache is false" do
          let(:non_cached_request) { Typhoeus::Request.new(base_url, {:method => :get, :cache => false}) }

          it "finishes request" do
            expect(non_cached_request.response).to_not be_truthy
            hydra.add(non_cached_request)
          end
        end

        context "when cache is defined" do
          let(:cached_request) { Typhoeus::Request.new(base_url, {:method => :get, :cache => cache}) }

          before { cache.memory[cached_request] = response }

          it "finishes request" do
            expect(cached_request).to receive(:finish).with(response)
            hydra.add(cached_request)
          end
        end
      end

    end
  end
end
