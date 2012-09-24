require 'spec_helper'

describe Typhoeus::Response::Informations do
  let(:options) { {} }
  let(:response) { Typhoeus::Response.new(options) }
  Typhoeus::Response::Informations::AVAILABLE_INFORMATIONS.each do |name|
    describe name do
      it "responds to" do
        expect(response).to respond_to(name)
      end
    end
  end

  describe "#headers" do
    context "when no headers" do
      it "returns nil" do
        expect(response.headers).to be_nil
      end
    end

    context "when headers" do
      let(:options) { {:response_header => "Expire: -1\nServer: gws"} }

      it "returns nonempty headers" do
        expect(response.headers).to_not be_empty
      end

      it "has Expire" do
        expect(response.headers['Expire']).to eq('-1')
      end

      it "has Server" do
        expect(response.headers['Server']).to eq('gws')
      end
    end

    context "when multiple headers" do
      let(:options) { {:response_header => "Server: A\r\n\r\nServer: B"} }

      it "returns the last" do
        expect(response.headers['Server']).to eq("B")
      end
    end
  end

  describe "#redirections" do
    context "when no response_header" do
      it "returns empty array" do
        expect(response.redirections).to be_empty
      end
    end

    context "when headers" do
      let(:options) { {:response_header => "Expire: -1\nServer: gws"} }

      it "returns empty array" do
        expect(response.redirections).to be_empty
      end
    end

    context "when multiple headers" do
      let(:options) { {:response_header => "Server: A\r\n\r\nServer: B"} }

      it "returns response from all but last headers" do
        expect(response.redirections).to have(1).item
      end
    end
  end
end
