require 'spec_helper'

describe Typhoeus::Pool do
  let(:easy) { Ethon::Easy.new }

  describe "#easies" do
    it "returns array" do
      expect(Typhoeus::Pool.easies).to be_a(Array)
    end
  end

  describe "#release" do
    it "resets easy" do
      easy.should_receive(:reset)
      Typhoeus::Pool.release(easy)
    end

    it "puts easy back into pool" do
      Typhoeus::Pool.release(easy)
      expect(Typhoeus::Pool.easies).to include(easy)
    end
  end

  describe "#get" do
    context "when easy in pool" do
      before { Typhoeus::Pool.easies << easy }

      it "takes" do
        expect(Typhoeus::Pool.get).to eq(easy)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        Ethon::Easy.should_receive(:new)
        Typhoeus::Pool.get
      end
    end
  end
end
