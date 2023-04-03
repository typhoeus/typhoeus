require 'spec_helper'

describe Typhoeus::Errors::NoStub do
  subject { Typhoeus::Errors::NoStub }

  let(:base_url) { 'localhost:3001' }
  let(:request) { Typhoeus::Request.new(base_url) }
  let(:message) { 'The connection is blocked and no stub defined: ' }

  it 'displays the request url' do
    expect { raise subject, request }.to raise_error(subject, message + base_url)
  end
end
