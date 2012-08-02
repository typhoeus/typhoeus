require 'spec_helper'

describe Typhoeus::Expectation do
  let(:options) { {} }
  let(:url) { "www.example.com" }
  let(:expectation) { described_class.new(url, options) }

  describe ".new" do
  end

  describe ".find_by" do
    let(:request) { Typhoeus::Request.new("") }

    before { Typhoeus.expectations.clear }

    it "returns a dummy when expectations not empty" do
      Typhoeus.expectations << expectation
      expectation.should_receive(:matches?).with(request).and_return(true)
      expect(Typhoeus::Expectation.find_by(request)).to eq(expectation)
    end
  end

  describe "#and_return" do
    it "adds value to responses" do
      expectation.and_return(1)
      expect(expectation.responses).to eq([1])
    end
  end

  describe "#responses" do
    it "returns responses" do
      expect(expectation.responses).to be_a(Array)
    end
  end

  describe "#response" do
    it "returns last response" do
      expectation.responses << 1 << 2
      expect(expectation.response).to eq(2)
    end

    it "is clever"
  end

  describe "#matches" do
    let(:request_url) { "www.example.com" }
    let(:request_options) { {} }
    let(:request) { Typhoeus::Request.new(request_url, request_options) }

    context "when url" do
      context "when match" do
        it "returns true" do
          expect(expectation.matches?(request)).to be_true
        end

        context "when options" do
          context "when match" do
            let(:options) { { :a => 1 } }
            let(:request_options) { options }

            it "returns true" do
              expect(expectation.matches?(request)).to be_true
            end
          end

          context "when options are a subset from request_options" do
            let(:options) { { :a => 1 } }
            let(:request_options) { { :a => 1, :b => 2 } }

            it "returns true" do
              expect(expectation.matches?(request)).to be_true
            end
          end

          context "when options are nested" do
            let(:options) { { :a => { :b => 1 } } }
            let(:request_options) { options }

            it "returns true" do
              expect(expectation.matches?(request)).to be_true
            end
          end

          context "when options contains an array" do
            let(:options) { { :a => [1, 2] } }
            let(:request_options) { options }

            it "returns true" do
              expect(expectation.matches?(request)).to be_true
            end
          end

          context "when no match" do
            let(:options) { { :a => 1 } }

            it "returns false" do
              expect(expectation.matches?(request)).to be_false
            end
          end
        end
      end

      context "when no match" do
        let(:request_url) { "www.different.com" }

        it "returns false" do
          expect(expectation.matches?(request)).to be_false
        end

        context "when options" do
          context "when match" do
            let(:options) { { :a => 1 } }
            let(:request_options) { options }

            it "returns false" do
              expect(expectation.matches?(request)).to be_false
            end
          end
        end
      end
    end

    context "when no url" do
      let(:url) { nil }

      context "when options" do
        context "when match" do
          let(:options) { { :a => 1 } }
          let(:request_options) { options }

          it "returns true" do
            expect(expectation.matches?(request)).to be_true
          end
        end

        context "when no match" do
          let(:options) { { :a => 1 } }

          it "returns false" do
            expect(expectation.matches?(request)).to be_false
          end
        end
      end
    end
  end
end
