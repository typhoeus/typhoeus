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
  end

  describe "#hydra" do
    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end
  end
end
