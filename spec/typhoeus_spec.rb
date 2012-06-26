require 'spec_helper'

describe Typhoeus do
  describe ".configure" do
    before { Typhoeus.configure { |config| config.verbose = true } }
    after { Typhoeus.configure { |config| config.verbose = false } }

    it "yields config" do
      Typhoeus.configure do |config|
        config.should be_a(Typhoeus::Config)
      end
    end

    it "sets values config" do
      Typhoeus::Config.verbose.should be_true
    end
  end

  [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
    describe ".#{name}" do
      let(:response) { Typhoeus::Request.method(name).call("http://localhost:3001", {}) }

      it "returns ok" do
        response.return_code.should eq(:ok)
      end

      unless name == :head
        it "makes #{name.to_s.upcase} requests" do
          response.response_body.should include("\"REQUEST_METHOD\":\"#{name.to_s.upcase}\"")
        end
      end
    end
  end
end
