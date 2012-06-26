require 'spec_helper'

describe Typhoeus::Hydras::EasyPool do
  let(:easy) { Ethon::Easy.new }

  describe "#easy_pool" do
    it "returns array" do
      Typhoeus.easy_pool.should be_a(Array)
    end
  end

  describe "#release_easy" do
    it "resets easy" do
      easy.expects(:reset)
      Typhoeus.release_easy(easy)
    end

    it "puts easy back into pool" do
      Typhoeus.release_easy(easy)
      Typhoeus.easy_pool.should include(easy)
    end
  end

  describe "#get_easy" do
    context "when easy in pool" do
      before { Typhoeus.easy_pool << easy }
      after { Typhoeus.easy_pool.clear }

      it "takes" do
        Typhoeus.get_easy.should eq(easy)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        Ethon::Easy.expects(:new)
        Typhoeus.get_easy
      end
    end
  end
end
