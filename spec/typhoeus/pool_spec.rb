require 'spec_helper'

describe Typhoeus::Pool do
  let(:easy) { Ethon::Easy.new }
  after { Typhoeus::Pool.clear }

  describe "#easies" do
    it "returns array" do
      expect(Typhoeus::Pool.send(:easies)).to be_a(Array)
    end
  end

  describe "#release" do
    it "resets easy" do
      expect(easy).to receive(:reset)
      Typhoeus::Pool.release(easy)
    end

    it "puts easy back into pool" do
      Typhoeus::Pool.release(easy)
      expect(Typhoeus::Pool.send(:easies)).to include(easy)
    end

    context "when threaded access" do
      it "releases correct number of easies" do
        (0..9).map do |n|
          Thread.new do
            Typhoeus::Pool.release(Ethon::Easy.new)
          end
        end.map(&:join)
        expect(Typhoeus::Pool.send(:easies).size).to eq(10)
      end
    end
  end

  describe "#get" do
    context "when easy in pool" do
      before { Typhoeus::Pool.send(:easies) << easy }

      it "takes" do
        expect(Typhoeus::Pool.get).to eq(easy)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        expect(Typhoeus::Pool.get).to be_a(Ethon::Easy)
      end

      context "when threaded access" do
        it "creates correct number of easies" do
          array = []
          (0..9).map do |n|
            Thread.new do
              array << Typhoeus::Pool.get
            end
          end.map(&:join)
          expect(array.uniq.size).to eq(10)
        end
      end
    end

    context "when forked" do
      before do
        allow(Process).to receive(:pid).and_return(1)
        Typhoeus::Pool.send(:easies) << easy
        allow(Process).to receive(:pid).and_return(2)
      end

      after do
        allow(Process).to receive(:pid).and_call_original
        Typhoeus::Pool.instance_variable_set(:@pid, Process.pid)
      end

      it "creates" do
        expect(Typhoeus::Pool.get).to_not eq(easy)
      end
    end
  end

  describe "#with" do
    it "is re-entrant" do
      array = []
      Typhoeus::Pool.with_easy do |e1|
        array << e1
        Typhoeus::Pool.with_easy do |e2|
          array << e2
          Typhoeus::Pool.with_easy do |e3|
            array << e3
          end
        end
      end
      expect(array.uniq.size).to eq(3)
    end
  end
end
