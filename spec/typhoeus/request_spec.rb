require 'spec_helper'

describe Typhoeus::Request do
  let(:url) { "localhost:3001" }
  let(:options) { {:verbose => true, :headers => { 'User-Agent' => "Fubar" }} }
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

    context "when Config.verbose set" do
      before { Typhoeus.configure { |config| config.verbose = true} }
      after { Typhoeus.configure { |config| config.verbose = false} }

      it "respects" do
        request.options[:verbose].should be_true
      end
    end
  end

  describe "#eql?" do
    context "when another class" do
      let(:other) { "" }

      it "returns false" do
        request.eql?(other).should be_false
      end
    end

    context "when same class" do
      let(:other) { Typhoeus::Request.new("url", options) }

      context "when other url" do
        it "returns false" do
          request.eql?(other).should be_false
        end
      end

      context "when same url and other options" do
        let(:other) { Typhoeus::Request.new(url, {}) }

        it "returns false" do
          request.eql?(other).should be_false
        end
      end

      context "when same url and same options are given, but options have different order" do
        let(:other_options) { {:headers => { 'User-Agent' => "Fubar" }, :verbose => true } }
        let(:other) { Typhoeus::Request.new(url, other_options)}

        it "returns true" do
          request.eql?(other).should be_true
        end
      end

      context "when same url and options" do
        let(:other) { Typhoeus::Request.new(url, options) }

        it "returns true" do
          request.eql?(other).should be_true
        end
      end
    end
  end

  describe "#hash" do
    context "when request.eql?(other)" do
      let(:other) { Typhoeus::Request.new(url, options) }

      it "has same hashes" do
        request.hash.should eq(other.hash)
      end
    end

    context "when not request.eql?(other)" do
      let(:other) { Typhoeus::Request.new("url", {}) }

      it "has different hashes" do
        request.hash.should_not eq(other.hash)
      end
    end
  end
end
