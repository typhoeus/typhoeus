require 'spec_helper'

describe Typhoeus::Request do
  let(:base_url) { "localhost:3001" }
  let(:options) { {:verbose => true, :headers => { 'User-Agent' => "Fubar" }} }
  let(:request) { Typhoeus::Request.new(base_url, options) }

  describe ".url" do
    it "should be equal to base_url" do
      expect(request.base_url).to eq(request.url)
    end
  end
    
  describe ".new" do
    it "stores base_url" do
      expect(request.base_url).to eq(base_url)
    end

    it "stores options" do
      expect(request.options).to eq(options)
    end

    context "when header with user agent" do
      let(:options) { {:headers => {'User-Agent' => "Custom"} } }

      it "doesn't modify user agent" do
        expect(request.options[:headers]['User-Agent']).to eq("Custom")
      end
    end

    context "when header without user agent" do
      let(:options) { {:headers => {} } }

      it "add user agent" do
        expect(request.options[:headers]['User-Agent']).to eq(Typhoeus::USER_AGENT)
      end
    end

    context "when Config.verbose set" do
      before { Typhoeus.configure { |config| config.verbose = true} }
      after { Typhoeus.configure { |config| config.verbose = false} }

      it "respects" do
        expect(request.options[:verbose]).to be_true
      end
    end
  end

  describe "#eql?" do
    context "when another class" do
      let(:other) { "" }

      it "returns false" do
        expect(request).to_not eql other
      end
    end

    context "when same class" do
      let(:other) { Typhoeus::Request.new("base_url", options) }

      context "when other base_url" do
        it "returns false" do
          expect(request).to_not eql other
        end
      end

      context "when same base_url and other options" do
        let(:other) { Typhoeus::Request.new(base_url, {}) }

        it "returns false" do
          expect(request).to_not eql other
        end
      end


      context "when same base_url and options" do
        context "when same order" do
          let(:other) { Typhoeus::Request.new(base_url, options) }

          it "returns true" do
            expect(request).to eql other
          end
        end

        context "when different order" do
          let(:other_options) { {:headers => { 'User-Agent' => "Fubar",  }, :verbose => true } }
          let(:other) { Typhoeus::Request.new(base_url, other_options)}

          it "returns true" do
            expect(request).to eql other
          end
        end
      end
    end
  end

  describe "#hash" do
    context "when request.eql?(other)" do
      let(:other) { Typhoeus::Request.new(base_url, options) }

      it "has same hashes" do
        expect(request.hash).to eq(other.hash)
      end
    end

    context "when not request.eql?(other)" do
      let(:other) { Typhoeus::Request.new("base_url", {}) }

      it "has different hashes" do
        expect(request.hash).to_not eq(other.hash)
      end
    end
  end
end
