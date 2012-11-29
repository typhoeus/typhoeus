require 'spec_helper'

describe Typhoeus::Expectation do
  let(:options) { {} }
  let(:url) { "www.example.com" }
  let(:expectation) { described_class.new(url, options) }

  after(:each) { Typhoeus::Expectation.clear }

  describe ".new" do
    it "sets url" do
      expect(expectation.instance_variable_get(:@url)).to eq(url)
    end

    it "sets options" do
      expect(expectation.instance_variable_get(:@options)).to eq(options)
    end

    it "initializes response_counter" do
      expect(expectation.instance_variable_get(:@response_counter)).to eq(0)
    end
  end

  describe ".all" do
    context "when @expectations nil" do
      it "returns empty array" do
        expect(Typhoeus::Expectation.all).to eq([])
      end
    end

    context "when @expectations not nil" do
      let(:expectations) { [1] }

      it "returns @expectations" do
        Typhoeus::Expectation.instance_variable_set(:@expectations, expectations)
        expect(Typhoeus::Expectation.all).to be(expectations)
      end
    end
  end

  describe ".clear" do
    let(:expectations) { mock(:clear) }

    it "clears all" do
      expectations.should_receive(:clear)
      Typhoeus::Expectation.instance_variable_set(:@expectations, expectations)
      Typhoeus::Expectation.clear
      Typhoeus::Expectation.instance_variable_set(:@expectations, nil)
    end
  end

  describe ".find_by" do
    let(:request) { Typhoeus::Request.new("") }

    it "returns a dummy when expectations not empty" do
      Typhoeus::Expectation.all << expectation
      expectation.should_receive(:matches?).with(request).and_return(true)
      expect(Typhoeus::Expectation.find_by(request)).to eq(expectation)
    end
  end

  describe "#stubbed_from" do
    it "sets value" do
      expectation.stubbed_from(:webmock)
      expect(expectation.from).to eq(:webmock)
    end

    it "returns self" do
      expect(expectation.stubbed_from(:webmock)).to be(expectation)
    end
  end

  describe "#and_return" do
    context "when value" do
      it "adds to responses" do
        expectation.and_return(1)
        expect(expectation.responses).to eq([1])
      end
    end

    context "when array" do
      it "adds to responses" do
        pending
        expectation.and_return([1, 2])
        expect(expectation.responses).to eq([1, 2])
      end
    end
  end

  describe "#responses" do
    it "returns responses" do
      expect(expectation.responses).to be_a(Array)
    end
  end

  describe "#response" do
    before { expectation.instance_variable_set(:@responses, responses) }

    context "when one response" do
      let(:responses) { [Typhoeus::Response.new] }

      it "returns response" do
        expect(expectation.response).to be(responses[0])
      end
    end

    context "when multiple responses" do
      let(:responses) { [Typhoeus::Response.new, Typhoeus::Response.new, Typhoeus::Response.new] }

      it "returns one by one" do
        3.times do |i|
          expect(expectation.response).to eq(responses[i])
        end
      end
    end
  end

  describe "#matches?" do
    let(:request) { stub(:url => nil) }

    it "calls url_match?" do
      expectation.should_receive(:url_match?)
      expectation.matches?(request)
    end

    it "calls options_match?" do
      expectation.should_receive(:url_match?).and_return(true)
      expectation.should_receive(:options_match?)
      expectation.matches?(request)
    end
  end

  describe "#url_match?" do
    let(:request_url) { "www.example.com" }
    let(:request) { Typhoeus::Request.new(request_url) }
    let(:url_match) { expectation.method(:url_match?).call(request.url) }

    context "when string" do
      context "when match" do
        it "returns true" do
          expect(url_match).to be_true
        end
      end

      context "when no match" do
        let(:url) { "no_match" }

        it "returns false" do
          expect(url_match).to be_false
        end
      end
    end

    context "when regexp" do
      context "when match" do
        let(:url) { /example/ }

        it "returns true" do
          expect(url_match).to be_true
        end
      end

      context "when no match" do
        let(:url) { /nomatch/ }

        it "returns false" do
          expect(url_match).to be_false
        end
      end
    end

    context "when nil" do
      let(:url) { nil }

      it "returns true" do
        expect(url_match).to be_true
      end
    end

    context "when not string, regexp, nil" do
      let(:url) { 1 }

      it "returns false" do
        expect(url_match).to be_false
      end
    end
  end

  describe "options_match?" do
    let(:request_options) { {} }
    let(:request) { Typhoeus::Request.new(nil, request_options) }
    let(:options_match) { expectation.method(:options_match?).call(request) }

    context "when match" do
      let(:options) { { :a => 1 } }
      let(:request_options) { options }

      it "returns true" do
        expect(options_match).to be_true
      end
    end

    context "when options are a subset from request_options" do
      let(:options) { { :a => 1 } }
      let(:request_options) { { :a => 1, :b => 2 } }

      it "returns true" do
        expect(options_match).to be_true
      end
    end

    context "when options are nested" do
      let(:options) { { :a => { :b => 1 } } }
      let(:request_options) { options }

      it "returns true" do
        expect(options_match).to be_true
      end
    end

    context "when options contains an array" do
      let(:options) { { :a => [1, 2] } }
      let(:request_options) { options }

      it "returns true" do
        expect(options_match).to be_true
      end
    end

    context "when no match" do
      let(:options) { { :a => 1 } }

      it "returns false" do
        expect(options_match).to be_false
      end
    end
  end
end
