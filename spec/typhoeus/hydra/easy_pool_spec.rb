require 'spec_helper'

describe Typhoeus::Hydra::EasyPool do
  let(:easy) { Ethon::Easy.new }

  before { Typhoeus.easy_pool.clear }

  describe "#easy_pool" do
    it "returns array" do
      expect(Typhoeus.easy_pool).to be_a(Array)
    end
  end

  describe "#release_easy" do
    it "resets easy" do
      easy.should_receive(:reset)
      Typhoeus.release_easy(easy)
    end

    it "puts easy back into pool" do
      Typhoeus.release_easy(easy)
      expect(Typhoeus.easy_pool).to include(easy)
    end
  end

  describe "#get_easy" do
    context "when easy in pool" do
      before { Typhoeus.easy_pool << easy }
      after { Typhoeus.easy_pool.clear }

      it "takes" do
        expect(Typhoeus.get_easy).to eq(easy)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        Ethon::Easy.should_receive(:new)
        Typhoeus.get_easy
      end
    end
  end
end
