require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }
  let(:multi) { Ethon::Multi.new }

  describe "#hydra" do
    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end
  end

  describe "#multi" do
    before do
      allow(Typhoeus::Pooling::Multis).to receive(:get).and_return(multi)
    end

    it "takes from pool" do
      expect(hydra.multi).to eq(multi)
    end

    context "with custom options" do
      let(:options) { { :maxconnects => 100 } }
      it "sets multi attributes" do
        expect(multi).to receive(:set_attributes).with(options)
        hydra.multi
      end
    end
  end
end
