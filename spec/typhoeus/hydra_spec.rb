# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#new" do
    let(:options) { {:pipeling => true} }

    it "passes options to multi" do
      expect(Ethon::Multi).to receive(:new).with(options)
      hydra
    end

    context "when max_concurrency is zero" do
      let(:options) { { :max_concurrency => 0 } }

      it "raises" do
        expect { hydra }.to raise_error(ArgumentError, /max_concurrency/)
      end
    end

    context "when max_concurrency is negative" do
      let(:options) { { :max_concurrency => -1 } }

      it "raises" do
        expect { hydra }.to raise_error(ArgumentError, /max_concurrency/)
      end
    end

    context "when max_concurrency is not set" do
      let(:options) { {} }

      it "defaults to 200" do
        expect(hydra.max_concurrency).to eq(200)
      end
    end

    context "when max_concurrency is set after creation" do
      let(:options) { {} }

      it "raises for zero" do
        expect { hydra.max_concurrency = 0 }.to raise_error(ArgumentError, /max_concurrency/)
      end

      it "raises for a negative value" do
        expect { hydra.max_concurrency = -1 }.to raise_error(ArgumentError, /max_concurrency/)
      end

      it "accepts a numeric string" do
        hydra.max_concurrency = "2"

        expect(hydra.max_concurrency).to eq(2)
      end
    end
  end

  describe "#hydra" do
    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end
  end

  describe "#add" do
    it "sets the hydra on the request" do
      Typhoeus.stub(base_url).and_return(Typhoeus::Response.new)
      request = Typhoeus::Request.new(base_url)

      hydra.add(request)

      expect(request.hydra).to be(hydra)
    end
  end
end
