require 'spec_helper'

describe Typhoeus do
  before(:each) do
    Typhoeus.configure { |config| config.verbose = false; config.block_connection = false }
  end

  describe ".configure" do
    it "yields config" do
      Typhoeus.configure do |config|
        expect(config).to be_a(Typhoeus::Config)
      end
    end

    it "sets values config" do
      Typhoeus::Config.verbose = true
      expect(Typhoeus::Config.verbose).to be_true
    end
  end

  describe ".stub" do
    let(:url) { "www.example.com" }
    before { Typhoeus::Expectation.clear }

    context "when no similar expectation exists" do
      it "returns expectation" do
        expect(Typhoeus.stub(url)).to be_a(Typhoeus::Expectation)
      end

      it "adds expectation" do
        Typhoeus.stub(:get, "")
        expect(Typhoeus::Expectation.all).to have(1).item
      end
    end

    context "when similar expectation exists" do
      let(:expectation) { Typhoeus::Expectation.new(url) }
      before { Typhoeus::Expectation.all << expectation }

      it "returns expectation" do
        expect(Typhoeus.stub(url)).to be_a(Typhoeus::Expectation)
      end

      it "doesn't add expectation" do
        Typhoeus.stub(url)
        expect(Typhoeus::Expectation.all).to have(1).item
      end
    end
  end

  describe ".before" do
    after { Typhoeus.before.clear }

    it "adds callback" do
      Typhoeus.before { true }
      expect(Typhoeus.before).to have(1).item
    end
  end

  describe ".with_connection" do
    it "executes block with block connection is false" do
      Typhoeus.with_connection { expect(Typhoeus::Config.block_connection).to be(false) }
    end

    it "sets block connection back to previous value" do
      Typhoeus::Config.block_connection = true
      Typhoeus.with_connection {}
      expect(Typhoeus::Config.block_connection).to be(true)
    end

    it "returns result of block" do
      expect(Typhoeus.with_connection { "123" }).to eq("123")
    end
  end

  [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
    describe ".#{name}" do
      let(:response) { Typhoeus::Request.method(name).call("http://localhost:3001") }

      it "returns ok" do
        expect(response.return_code).to eq(:ok)
      end

      unless name == :head
        it "makes #{name.to_s.upcase} requests" do
          expect(response.response_body).to include("\"REQUEST_METHOD\":\"#{name.to_s.upcase}\"")
        end
      end
    end
  end
end
