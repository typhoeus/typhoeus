# frozen_string_literal: true

require 'spec_helper'
require "rack/typhoeus"

class FakeParams
  def initialize(hash)
    @hash = hash
  end

  def each_pair(&block)
    @hash.each_pair(&block)
  end

  def [](key)
    @hash[key]
  end

  def []=(key, value)
    @hash[key] = value
  end

  # ActionController::Parameters#to_h raises for unpermitted parameters.
  def to_h
    raise "UnfilteredParameters"
  end
end

describe "Rack::Typhoeus::Middleware::ParamsDecoder::Helper" do

  let(:klass) do
    Class.new do
      include Rack::Typhoeus::Middleware::ParamsDecoder::Helper
    end.new
  end

  describe "#decode" do
    let(:decoded) { klass.decode(params) }
    let(:params) { { :array => {'0' => :a, '1' => :b } } }

    it "decodes" do
      expect(decoded[:array]).to match_array([:a, :b])
    end

    it "doesn't modify" do
      expect(decoded).to_not be(params)
    end

    context "when nested" do
      let(:params) { { "a" => { "0" => { "0" => "x", "1" => "y" } } } }

      it "does not modify the input" do
        klass.decode(params)

        expect(params).to eq("a" => { "0" => { "0" => "x", "1" => "y" } })
      end
    end

    context "when the value is an array" do
      let(:params) { { "a" => [{ "b" => "c" }] } }

      it "does not share the array with the input" do
        decoded = klass.decode(params)
        decoded["a"] << { "d" => "e" }

        expect(params["a"]).to eq([{ "b" => "c" }])
      end

      it "decodes encoded hashes inside the array" do
        params = { "a" => [{ "0" => "x", "1" => "y" }] }

        expect(klass.decode(params)["a"]).to eq([["x", "y"]])
      end
    end

    context "when given an array" do
      let(:params) { [{ "0" => "x", "1" => "y" }] }

      it "decodes the array" do
        expect(klass.decode(params)).to eq([["x", "y"]])
      end
    end
  end

  describe "#decode!" do
    let(:decoded) { klass.decode!(params) }

    context "when hash" do
      context "when encoded" do
        context "when simple" do
          let(:params) { { :array => {'0' => :a, '1' => :b } } }

          it "decodes" do
            expect(decoded[:array]).to match_array([:a, :b])
          end

          it "modifies" do
            expect(decoded).to eq(params)
          end
        end

        context "when longer and more complex" do
          let(:params) do
            {
              :ids => {
                "0"  => "407304",
                "1"  => "407305",
                "2"  => "407306",
                "3"  => "407307",
                "4"  => "407308",
                "5"  => "407309",
                "6"  => "407310",
                "7"  => "407311",
                "8"  => "407312",
                "9"  => "407313",
                "10" => "327012"
              }
            }
          end

          it "decodes ensuring arrays maintain their original order" do
            expect(decoded[:ids]).to eq(["407304", "407305", "407306", "407307", "407308", "407309", "407310", "407311", "407312", "407313", "327012"])
          end
        end

        context "when nested" do
          let(:params) do
            { :array => { '0' => 0, '1' => { '0' => 'sub0', '1' => 'sub1' } } }
          end

          it "decodes" do
            expect(decoded[:array]).to include(0)
            expect(decoded[:array].find{|e| e.is_a?(Array)}).to(
              match_array(['sub0', 'sub1'])
            )
          end

          it "modifies" do
            expect(decoded).to eq(params)
          end
        end
      end

      context "when not encoded" do
        let(:params) { {:a => :a} }

        it "doesn't modify" do
          expect(decoded).to be(params)
        end
      end
    end

    context "when array" do
      let(:params) { ["a", { "0" => "x", "1" => "y" }] }

      it "decodes in place" do
        expect(decoded).to eq(["a", ["x", "y"]])
        expect(decoded).to be(params)
      end
    end

    context "when hash-like" do
      let(:params) { { "a" => FakeParams.new("0" => "x", "1" => "y") } }

      it "decodes" do
        expect(decoded["a"]).to eq(["x", "y"])
      end
    end

    context "when the params themselves are hash-like" do
      let(:params) { FakeParams.new("a" => { "0" => "x", "1" => "y" }) }

      it "decodes" do
        expect(decoded["a"]).to eq(["x", "y"])
      end
    end

    context "when symbol keys" do
      let(:params) { { "a" => { :"0" => "x", :"1" => "y" } } }

      it "decodes" do
        expect(decoded["a"]).to eq(["x", "y"])
      end
    end

    context "when no hash" do
      let(:params) { "a" }

      it "returns self" do
        expect(decoded).to be(params)
      end
    end
  end

  describe "#encoded?" do
    let(:encoded) { klass.send(:encoded?, params) }

    context "when there is only one key" do
      context "and its 0" do
        let(:params){ {'0' => 1} }
        it 'returns true' do
          expect(encoded).to be_truthy
        end
      end
      context "and its not 0" do
        let(:params){ {'some-key' => 1}}
        it 'returns false' do
          expect(encoded).to be_falsey
        end
      end

      context "and it contains a zero" do
        let(:params){ {'a0' => 1} }
        it 'returns false' do
          expect(encoded).to be_falsey
        end
      end

      context "and it is 10" do
        let(:params){ {'10' => 1} }
        it 'returns false' do
          expect(encoded).to be_falsey
        end
      end
    end

    context "when keys are ascending numbers starting with zero" do
      let(:params) { Hash[12.times.map {|i| [i, (i+65).chr]}] }

      it "returns true" do
        expect(encoded).to be_truthy
      end
    end

    context "when there are multiple keys but they are not numeric" do
      let(:params) { {'10' => 1, 'a0' => 2} }

      it "returns false" do
        expect(encoded).to be_falsey
      end
    end

    context "when keys are not ascending numbers starting with zero" do
      let(:params) { {:a => 1} }

      it "returns false" do
        expect(encoded).to be_falsey
      end
    end

    context "when keys are not canonical numbers" do
      let(:params) { {'0' => 1, '01' => 2} }

      it "returns false" do
        expect(encoded).to be_falsey
      end
    end

    context "when keys contain non-numbers" do
      let(:params) { {'0' => 1, '1x' => 2} }

      it "returns false" do
        expect(encoded).to be_falsey
      end
    end
  end

  describe "#convert" do
    let(:converted) { klass.send(:convert, params) }

    context "when encoded" do
      let(:params) { {'0' => :a, '1' => :b} }

      it "returns values" do
        expect(converted).to match_array([:a, :b])
      end
    end

    context "when not encoded" do
      let(:params) { {:a => :a} }

      it "returns unmodified" do
        expect(converted).to be(params)
      end
    end
  end
end
