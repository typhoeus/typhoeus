require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe ".hydra" do
    it "returns a hydra" do
      Typhoeus::Hydra.hydra.should be_a(Typhoeus::Hydra)
    end
  end

  describe ".hydra=" do
    after { Typhoeus::Hydra.hydra = Typhoeus::Hydra.new }

    it "sets hydra" do
      Typhoeus::Hydra.hydra = :foo
      Typhoeus::Hydra.hydra.should eq(:foo)
    end
  end

  describe "#fire_and_forget" do
    it
  end

  context "mocking and stubbing" do
    it
  end

  context "caching and memoization" do
    it
  end
end
