require 'spec_helper'

describe Typhoeus::Responses::Legacy do
  let(:response) { Typhoeus::Response.new(options) }
  let(:value) { "fubar" }

  Typhoeus::Responses::Legacy::MAPPING.each do |old, new|
    describe "##{old}" do
      let(:options) { {new => value} }

      it "aliases #{new}" do
        expect(response.method(old).call).to eq(value)
      end
    end
  end
end
