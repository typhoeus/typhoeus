require 'spec_helper'

describe Typhoeus::Request do
  let(:url) { "localhost:3001" }
  let(:options) { {:headers => { 'User-Agent' => "Fuabr" }} }
  let(:request) { Typhoeus::Request.new(url, options) }

  describe ".new" do
    it "stores url" do
      request.url.should eq(url)
    end

    it "stores options" do
      request.options.should eq(options)
    end

    context "when header with user agent" do
      let(:options) { {:headers => {'User-Agent' => "Custom"} } }

      it "doesn't modify user agent" do
        request.options[:headers]['User-Agent'].should eq("Custom")
      end
    end

    context "when header without user agent" do
      let(:options) { {:headers => {} } }

      it "add user agent" do
        request.options[:headers]['User-Agent'].should eq(Typhoeus::USER_AGENT)
      end
    end
  end
end
