# frozen_string_literal: true

require 'spec_helper'

describe "Typhoeus::VERSION" do
  it "is a semantic version" do
    expect(Typhoeus::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
