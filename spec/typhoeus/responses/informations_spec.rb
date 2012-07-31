require 'spec_helper'

describe Typhoeus::Responses::Informations do
  let(:options) { {} }
  let(:response) { Typhoeus::Response.new(options) }
  Typhoeus::Responses::Informations::AVAILABLE_INFORMATIONS.each do |name|
    describe name do
      it "responds to" do
        expect(response).to respond_to(name)
      end
    end
  end

  describe "#header" do
    context "when no header" do
      it "returns nil" do
        expect(response.header).to be_nil
      end
    end

    context "when header" do
      let(:options) { {:response_header => "Expire: -1\nServer: gws"} }

      it "returns nonempty header" do
        expect(response.header).to_not be_empty
      end

      it "has Expire" do
        expect(response.header['Expire']).to eq('-1')
      end

      it "has Server" do
        expect(response.header['Server']).to eq('gws')
      end
    end

    context "when multiple header" do
      let(:options) { {:response_header => "Server: A\r\n\r\nServer: B"} }

      it "returns the last" do
        expect(response.header['Server']).to eq("B")
      end
    end
  end

  describe "#redirections" do
    context "when no response_header" do
      it "returns empty array" do
        expect(response.redirections).to be_empty
      end
    end

    context "when header" do
      let(:options) { {:response_header => "Expire: -1\nServer: gws"} }

      it "returns empty array" do
        expect(response.redirections).to be_empty
      end
    end

    context "when multiple header" do
      let(:options) { {:response_header => "Server: A\r\n\r\nServer: B"} }

      it "returns response from all but last header" do
        expect(response.redirections).to have(1).item
      end
    end
  end
end
