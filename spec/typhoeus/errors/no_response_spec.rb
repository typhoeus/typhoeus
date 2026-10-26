# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Errors::NoResponse do
  it "names the stub url" do
    error = described_class.new("http://example.com")

    expect(error.message).to eq(
      'No response defined for stub: "http://example.com"'
    )
  end

  it "includes the reason" do
    error = described_class.new("http://example.com", "the block returned nil")

    expect(error.message).to eq(
      'No response defined for stub: "http://example.com" (the block returned nil)'
    )
  end

  it "is a Typhoeus error" do
    expect(described_class.new("url")).to be_a(Typhoeus::Errors::TyphoeusError)
  end
end
