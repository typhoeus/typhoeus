require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#hydra" do
    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end

    context "when threaded access" do
      it "gets distinct hydras" do
        hydras = (0...3).map do
          Thread.new { Typhoeus::Hydra.hydra }
        end.map(&:value)
        expect(hydras.uniq.size).to eq(3)
      end
    end
  end

  describe "#with_hydra" do
    it "yields a hydra" do
      Typhoeus::Hydra.with_hydra do |hydra|
        expect(hydra).to be_a(Typhoeus::Hydra)
      end
    end

    it "releases multi back to pool" do
      Typhoeus::Hydra.with_hydra do |hydra|
        expect(Typhoeus::Pooling::Multis).to receive(:release).with(hydra.multi)
      end
    end
  end

  describe "#reset" do
    it "releases multi back to pool" do
      expect(Typhoeus::Pooling::Multis).to receive(:release).with(hydra.multi)
      hydra.reset
    end
  end

  describe "#multi" do
    let(:multi) { Ethon::Multi.new }

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
