require 'spec_helper'

describe Typhoeus::Hydras::Stubable do
  let(:url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(url, {:method => :get}) }

  describe "#queue" do
    it "checks expactations" do
      Typhoeus::Expectation.should_receive(:find_by).with(request)
      hydra.queue(request)
    end
  end
end
