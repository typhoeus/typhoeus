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

  describe "#mock" do
    context "when @mock" do
      before { response.mock = true }

      it "returns @mock" do
        expect(response.mock).to be_true
      end
    end

    context "when options[:mock]" do
      let(:options) { {:mock => true} }

      it "returns options[:mock]" do
        expect(response.mock).to be_true
      end
    end

    context "when @mock and options[:mock]" do
      let(:options) { {:mock => 1} }
      before { response.mock = 2 }

      it "returns @mock" do
        expect(response.mock).to be(2)
      end
    end
  end
end
