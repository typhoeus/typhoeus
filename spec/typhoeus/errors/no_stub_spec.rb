# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Errors::NoStub do
  let(:base_url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(base_url) }
  let(:message) { "The connection is blocked and no stub defined: " }

  subject { Typhoeus::Errors::NoStub }

  it "displays the request url" do
    expect { raise subject.new(request) }.to raise_error(subject, message + base_url)
  end

  it "does not fail because an unrelated option is invalid" do
    request = Typhoeus::Request.new(base_url, :not_an_option => 1)

    expect { raise subject.new(request) }.to raise_error(subject, message + base_url)
  end

  it "falls back to the base url when the full url cannot be built" do
    skip unless defined?(Ethon::Errors::ForkSafety)
    allow(request).to receive(:url).and_raise(Ethon::Errors::ForkSafety.new)

    expect { raise subject.new(request) }.to raise_error(subject, message + base_url)
  end
end
