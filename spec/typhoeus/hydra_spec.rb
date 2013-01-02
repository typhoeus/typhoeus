require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#new" do
    let(:options) { {:pipeling => true} }

    it "passes options to multi" do
      Ethon::Multi.should_receive(:new).with(options)
      hydra
    end
  end

  describe "#hydra" do
    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end
  end

  describe "#fire_and_forget" do
    it
  end

  describe "#cache getter and setter" do
    it
  end
end
