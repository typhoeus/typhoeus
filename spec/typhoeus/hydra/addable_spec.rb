require 'spec_helper'

describe Typhoeus::Hydra::Addable do
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new("localhost:3001", {:method => :get}) }

  it "asks easy factory for an easy" do
    multi = stub
    Typhoeus::Hydra::EasyFactory.should_receive(:new).with(request, hydra).and_return(stub(:get => 1))
    hydra.should_receive(:multi).and_return(multi)
    multi.should_receive(:add).with(1)
    hydra.add(request)
  end

  it "adds easy to multi" do
    multi = stub
    Typhoeus::Hydra::EasyFactory.should_receive(:new).with(request, hydra).and_return(stub(:get => 1))
    hydra.should_receive(:multi).and_return(multi)
    multi.should_receive(:add).with(1)
    hydra.add(request)
  end
end
