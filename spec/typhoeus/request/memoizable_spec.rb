# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request::Memoizable do
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new("fu", options) }
  let(:response) { Typhoeus::Response.new }
  let(:hydra) { Typhoeus::Hydra.new }

  describe "#memoizable?" do
    context "when memoization activated" do
      before { Typhoeus::Config.memoize = true }
      after { Typhoeus::Config.memoize = false }

      it "is true for a GET request" do
        expect(Typhoeus::Request.new("fu", :method => :get)).to be_memoizable
      end

      it "is true for a GET request in a different spelling" do
        expect(Typhoeus::Request.new("fu", :method => "GET")).to be_memoizable
      end

      it "is false for a non-GET request" do
        expect(Typhoeus::Request.new("fu", :method => :post)).not_to be_memoizable
      end

      it "is false for a streaming request" do
        request = Typhoeus::Request.new("fu", :method => :get)
        request.on_body { |_, _| }

        expect(request).not_to be_memoizable
      end
    end

    context "when memoization is disabled" do
      it "is false" do
        expect(Typhoeus::Request.new("fu", :method => :get)).not_to be_memoizable
      end
    end
  end

  describe "#response=" do
    context "when memoization activated" do
      before { Typhoeus::Config.memoize = true }
      after { Typhoeus::Config.memoize = false }

      context "when GET request" do
        let(:options) { {:method => :get} }
        before { request.hydra = hydra }

        it "stores response in memory" do
          request.response = response
          expect(hydra.memory[request]).to be
        end
      end

      context "when no GET request" do
        let(:options) { {:method => :post} }

        it "doesn't store response in memory" do
          request.response = response
          expect(hydra.memory[request]).to be_nil
        end
      end

      context "when no hydra" do
        let(:options) { {:method => :get} }

        it "doesn't raise" do
          expect { request.response = response }.to_not raise_error
        end
      end
    end
  end
end
