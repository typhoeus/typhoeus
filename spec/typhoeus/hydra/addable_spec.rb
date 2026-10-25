# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Hydra::Addable do
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new("localhost:3001", {:method => :get}) }

  it "asks easy factory for an easy" do
    multi = double
    expect(Typhoeus::EasyFactory).to receive(:new).with(request, hydra).and_return(double(:get => 1))
    expect(hydra).to receive(:multi).and_return(multi)
    expect(multi).to receive(:add).with(1)
    hydra.add(request)
  end

  it "adds easy to multi" do
    multi = double
    expect(Typhoeus::EasyFactory).to receive(:new).with(request, hydra).and_return(double(:get => 1))
    expect(hydra).to receive(:multi).and_return(multi)
    expect(multi).to receive(:add).with(1)
    hydra.add(request)
  end

  it "releases easy when adding to multi raises" do
    easy = double("easy")
    easy_factory = double("easy factory", :get => easy, :released? => false)
    multi = double("multi")

    allow(Typhoeus::EasyFactory).to receive(:new).with(request, hydra).and_return(easy_factory)
    allow(hydra).to receive(:multi).and_return(multi)
    allow(multi).to receive(:add).with(easy).and_raise("boom")

    expect(Typhoeus::Pool).to receive(:release).with(easy)
    expect { hydra.add(request) }.to raise_error("boom")
  end
end
