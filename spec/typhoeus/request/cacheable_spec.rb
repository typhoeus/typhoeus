require 'spec_helper'

describe Typhoeus::Request::Cacheable do
  let(:cache) {
    Class.new do
      attr_reader :memory

      def initialize
        @memory = {}
      end

      def get(request)
        memory[request]
      end

      def set(request, response)
        memory[request] = response
      end
    end.new
  }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new("http://localhost:3001", options) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus::Config.cache = cache }
  after { Typhoeus::Config.cache = false }

  describe "#response=" do
    context "when cache activated" do
      context "when nequest new" do
        it "caches response" do
          request.response = response
          expect(cache.memory[request]).to be
        end
      end

      context "when request in memory" do
        before { cache.memory[request] = response }

        it "finishes request" do
          request.should_receive(:finish).with(response)
          request.run
        end
      end
    end
  end

  describe "#run" do
    context "when cache activated" do
      before { Typhoeus::Config.cache = cache }
      after { Typhoeus::Config.cache = false }

      context "when request new" do
        it "fetches response" do
          expect(request.response).to_not be(response)
        end
      end

      context "when request in memory" do
        let(:response) { Typhoeus::Response.new }
        before { cache.memory[request] = response }

        it "finishes request" do
          request.should_receive(:finish).with(response)
          request.run
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
