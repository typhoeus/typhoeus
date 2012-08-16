require 'spec_helper'

describe Typhoeus::Response::Legacy do
  let(:response) { Typhoeus::Response.new(options) }
  let(:value) { "fubar" }

  Typhoeus::Response::Legacy::MAPPING.each do |old, new|
    describe "##{old}" do
      let(:options) { {new => value} }

      it "aliases #{new}" do
        expect(response.method(old).call).to eq(value)
      end
    end
  end
end
