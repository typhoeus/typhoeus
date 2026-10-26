# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Errors::InvalidOption do
  it "adds the replacement hint to Ethon's message" do
    error = described_class.new(:old, "\nPlease try new instead of old.")

    expect(error.message).to eq(
      "#{Ethon::Errors::InvalidOption.new(:old).message}\nPlease try new instead of old."
    )
  end

  it "keeps Ethon's message without a hint" do
    expect(described_class.new(:invalid).message).to eq(
      Ethon::Errors::InvalidOption.new(:invalid).message
    )
  end

  it "is an Ethon invalid option" do
    expect(described_class.new(:invalid)).to be_a(Ethon::Errors::InvalidOption)
  end
end
