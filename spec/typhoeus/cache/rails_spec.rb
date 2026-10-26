# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Cache::Rails do
  class RecordingRailsCache
    attr_reader :read_key, :written

    def read(key)
      @read_key = key
      nil
    end

    def write(key, value, options)
      @written = [key, value, options]
    end
  end

  let(:cache_store) { RecordingRailsCache.new }
  let(:cache) { described_class.new(cache_store) }
  let(:request) { Typhoeus::Request.new(TestServer.host, :cache_ttl => 5) }
  let(:response) { Typhoeus::Response.new(:body => "body") }

  describe "#get" do
    it "reads with the request cache key" do
      expect(cache.get(request)).to be_nil
      expect(cache_store.read_key).to eq(request.cache_key)
    end
  end

  describe "#set" do
    it "writes with the request cache key and ttl" do
      cache.set(request, response)

      key, value, options = cache_store.written
      expect(key).to eq(request.cache_key)
      expect(value).to be(response)
      expect(options).to eq(:expires_in => 5)
    end

    it "uses the default ttl" do
      cache = described_class.new(cache_store, :default_ttl => 60)
      request = Typhoeus::Request.new(TestServer.host)

      cache.set(request, response)

      expect(cache_store.written.last).to eq(:expires_in => 60)
    end

    it "omits an unset ttl" do
      request = Typhoeus::Request.new(TestServer.host)

      cache.set(request, response)

      expect(cache_store.written.last).to eq(:expires_in => nil)
    end
  end
end
