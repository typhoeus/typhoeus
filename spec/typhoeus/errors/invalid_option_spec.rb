# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Errors::InvalidOption do
  let(:help) { "\nThe option cache_timeout was removed." }
  let(:error) { described_class.new(:cache_timeout, help) }

  it "includes the Ethon message and the help" do
    expect(error.message).to eq(
      "#{Ethon::Errors::InvalidOption.new(:cache_timeout).message}#{help}"
    )
  end

  it "includes the help when the error is converted to a string" do
    expect(error.to_s).to eq(error.message)
    expect(error.to_s).to include("was removed")
  end

  it "includes the help in the inspect output" do
    expect(error.inspect).to include("was removed")
  end

  it "includes the help when raised without an explicit message" do
    expect { raise error }.to raise_error(described_class) do |raised|
      expect(raised.to_s).to include("was removed")
    end
  end
end
