require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

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
