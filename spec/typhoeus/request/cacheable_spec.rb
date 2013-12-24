require 'spec_helper'

describe Typhoeus::Request::Cacheable do
  let(:cache) { MemoryCache.new }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new("http://localhost:3001", options) }
  let(:other) { Typhoeus::Request.new("http://localhost:3001", options) }
  let(:response) { Typhoeus::Response.new }

  before { Typhoeus::Config.cache = cache }
  after { Typhoeus::Config.cache = false }

  describe "#response=" do
    context "when cache activated" do
      context "when request new" do
        it "caches response" do
          request.response = response
          other.run.should == response
        end

        it "doesn't set cached on response" do
          request.response = response
          expect(request.response.cached?).to be_false
        end
      end

      context "when request cached" do
        before { other.response = response }

        it "finishes request" do
          request.should_receive(:finish).with(response)
          request.run
        end

        it "sets cached to true for response" do
          request.run
          expect(request.response.cached?).to be_true
        end
      end
    end
  end

  describe "#run" do
    context "when cache activated" do
      context "when request cached" do
        let!(:response) { other.run }

        it "finishes request" do
          request.should_receive(:finish).with(response)
          request.run
        end
      end

      context "when requests match" do
        it "returns the cached response" do
          request.run.should == other.run
        end
      end

      context "when options differ" do
        let(:other) do
          Typhoeus::Request.new("http://localhost:3001", params: {foo: 'bar'})
        end

        it "doesn't use the cached response" do
          request.run.should_not == other.run
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
