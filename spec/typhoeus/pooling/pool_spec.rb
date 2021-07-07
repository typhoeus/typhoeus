require 'spec_helper'

describe Typhoeus::Pooling::Pool do
  let(:pool) { described_class.new }
  let(:resource) { Object.new }

  describe "#resources" do
    it "returns array" do
      expect(pool.resources).to be_a(Array)
    end
  end

  describe "#release" do
    it "puts resource back" do
      pool.release(resource)
      expect(pool.resources).to include(resource)
    end

    context "when threaded access" do
      it "releases correct number of resources" do
        (0..9).map do |n|
          Thread.new do
            pool.release(Object.new)
          end
        end.map(&:join)
        expect(pool.resources.size).to eq(10)
      end
    end
  end

  describe "#get" do
    context "when resource in pool" do
      before { pool.resources << resource }

      it "returns it" do
        expect(pool.get).to eq(resource)
      end

      context "when forked" do
        before do
          allow(Process).to receive(:pid).and_return(Process.pid + 1)
        end

        after do
          allow(Process).to receive(:pid).and_call_original
        end

        it "returns nil" do
          expect(pool.get).to be_nil
        end
      end
    end

    context "when no resources in pool" do
      it "returns nil" do
        expect(pool.get).to be_nil
      end
    end

    context "when threaded access" do
      before do
        10.times { pool.resources << Object.new }
      end

      it "gets correct number of resources" do
        resources = (0..9).map do |n|
          Thread.new do
            pool.get
          end
        end.map(&:value)

        expect(resources.uniq.compact.size).to eq(10)
      end
    end
  end

  describe "#clear" do
    context "when resources in pool" do
      before do
        2.times { pool.resources << Object.new }
      end
      it "clears resources" do
        pool.clear
        expect(pool.resources.size).to eq(0)
        expect(pool.get).to be_nil
      end
    end
  end

end
