require 'spec_helper'

describe Typhoeus::Pooling::Multis do
  let(:multis) { described_class }
  let(:pool) { multis.instance_variable_get('@pool') }
  let(:multi) { Ethon::Multi.new }
  after { multis.clear }

  describe "#release" do
    it "puts multi back into pool" do
      expect(pool).to receive(:release).with(multi)
      multis.release(multi)
    end

    context "when easy handles attached" do
      before { 2.times { multi.add(Ethon::Easy.new) } }

      it "unattaches them" do
        multis.release(multi)
        expect(multi.easy_handles.size).to eq(0)
      end

      it "releases them back to pool" do
        expect(Typhoeus::Pooling::Easies).to receive(:release).twice
        multis.release(multi)
      end
    end
  end

  describe "#get" do
    context "when multi in pool" do
      before { pool.resources << multi }

      it "takes" do
        expect(multis.get).to eq(multi)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        expect(multis.get).to be_a(Ethon::Multi)
      end
    end
  end
end
