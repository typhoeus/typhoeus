require 'spec_helper'

describe Typhoeus::Responses::Mock do
  let(:response) { Typhoeus::Response.new(options) }
  let(:options) { {} }

  describe "#mock?" do
    it "defaults to false" do
      response.mock?.should be_false
    end

    context "when mock option set" do
      let(:options) { {:mock => true } }

      it "returns true" do
        response.mock?.should be_true
      end
    end
  end
end
