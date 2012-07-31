require 'spec_helper'

describe Typhoeus::Response do
  let(:response) { Typhoeus::Response.new(options) }
  let(:options) { {} }

  describe ".new" do
    context "when options" do
      let(:options) { {:return_code => 2} }

      it "stores" do
        expect(response.options).to eq(options)
      end
    end
  end
end
