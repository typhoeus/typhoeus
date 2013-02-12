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
  let(:request) { Typhoeus::Request.new("fu", options) }
  let(:response) { Typhoeus::Response.new }

  describe "#response=" do
    context "when memoization activated" do
      before { Typhoeus::Config.cache = cache }
      after { Typhoeus::Config.cache = false }

      let(:options) { {:method => :get} }

      it "caches response" do
        request.response = response
        expect(cache.memory[request]).to be
      end
    end
  end
end
