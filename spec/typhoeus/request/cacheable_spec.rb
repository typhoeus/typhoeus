# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request::Cacheable do
  let(:cache) { MemoryCache.new }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new("http://localhost:3001", options) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus::Config.cache = cache }
  after { Typhoeus::Config.cache = false }

  describe "#response=" do
    context "when cache activated" do
      context "when request new" do
        it "caches response" do
          request.response = response
          expect(cache.memory[request]).to be
        end

        it "doesn't set cached on response" do
          request.response = response
          expect(request.response.cached?).to be_falsey
        end

        it "doesn't cache a streaming response" do
          request.on_body { |_, _| true }
          request.response = response
          expect(cache.memory[request]).to be_nil
        end

        it "doesn't cache a mock response" do
          response.mock = true
          request.response = response
          expect(cache.memory[request]).to be_nil
        end

        it "doesn't cache a transport failure" do
          response = Typhoeus::Response.new(:return_code => :operation_timedout)
          request.response = response
          expect(cache.memory).to be_empty
        end
      end

      context "when request in memory" do
        before { cache.memory[request] = response }

        it "finishes request" do
          expect(request).to receive(:finish).with(an_instance_of(Typhoeus::Response))
          request.run
        end

        context "when the cached request omitted the default method" do
          let(:request) do
            Typhoeus::Request.new("http://localhost:3001", :method => :get)
          end

          before do
            cache.memory[Typhoeus::Request.new("http://localhost:3001")] = response
          end

          it "hits the cache" do
            request.run

            expect(request.response.cached?).to be(true)
            expect(request.response).not_to be(response)
          end
        end

        it "sets cached to true for response" do
          request.run
          expect(request.response.cached?).to be_truthy
        end

        it "runs on_headers callbacks" do
          called = false
          request.on_headers { |_| called = true }
          request.run

          expect(called).to be(true)
        end

        it "finishes with a copy" do
          request.run

          expect(request.response).to_not be(response)
        end

        it "does not copy the cached callback result" do
          response.handled_response = :cached
          request.run

          expect(request.response.handled_response).to be(request.response)
        end

        it "does not change the cached response" do
          request.run

          expect(response.request).to be_nil
          expect(response.cached?).to be(false)
        end

        it "sets the request for header callbacks" do
          seen_request = nil
          request.on_headers { |header_response| seen_request = header_response.request }

          request.run

          expect(seen_request).to be(request)
        end

        it "passes the cached body to on_body callbacks" do
          response = Typhoeus::Response.new(:body => "cached body")
          Typhoeus::Config.cache.memory[request] = response
          chunks = []
          request.on_body { |chunk, _| chunks << chunk }
          request.run

          expect(chunks).to eq(["cached body"])
        end
      end
    end
  end

  describe "#run" do
    context "when cache activated" do
      context "when request new" do
        it "fetches response" do
          expect(request.response).to_not be(response)
        end
      end

      context "when request in memory" do
        before { cache.memory[request] = response }

        it "finishes request" do
          expect(request).to receive(:finish).with(an_instance_of(Typhoeus::Response))
          request.run
        end
      end

      context "when cache is specified on a request" do
        before { Typhoeus::Config.cache = false }

        context "when cache is false" do
          let(:options) { { :cache => false } }

          it "finishes request" do
            expect(request.response).to_not be(response)
            request.run
          end
        end

        context "when cache is defined" do
          let(:options) { { :cache => cache } }

          before { cache.memory[request] = response }

          it "finishes request" do
            expect(request).to receive(:finish).with(an_instance_of(Typhoeus::Response))
            request.run
          end
        end
      end
    end
  end

  describe "#cache_ttl" do
    context "when option[:cache_ttl]" do
      let(:options) { {:cache_ttl => 1} }

      it "returns" do
        expect(request.cache_ttl).to be(1)
      end
    end
  end
end
