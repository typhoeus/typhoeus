# frozen_string_literal: true

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
    context "when cleanup is requested" do
      it "cleans up instead of pooling" do
        expect(easy).to receive(:cleanup)
        Typhoeus::Pool.release(easy, :cleanup => true)
        expect(Typhoeus::Pool.send(:easies)).to be_empty
      end
    end

    it "resets easy" do
      expect(easy).to receive(:reset)
      Typhoeus::Pool.release(easy)
    end

    it "flush cookies to disk" do
      expect(easy).to receive(:cookielist=).with('flush')
      expect(easy).to receive(:reset)
      expect(easy).to receive(:cookielist=).with('all')
      Typhoeus::Pool.release(easy)
    end

    it "writes cookies to disk" do
      tempfile1 = Tempfile.new('cookies')
      tempfile2 = Tempfile.new('cookies')

      easy.cookiejar = tempfile1.path
      easy.url = "localhost:3001/cookies-test"
      easy.perform

      Typhoeus::Pool.release(easy)

      expect(File.zero?(tempfile1.path)).to be(false)
      expect(File.read(tempfile1.path)).to match(/\s+foo\s+bar$/)
      expect(File.read(tempfile1.path)).to match(/\s+bar\s+foo$/)

      # do it again - and check if tempfile1 wasn't change
      easy.cookiejar = tempfile2.path
      easy.url = "localhost:3001/cookies-test2"
      easy.perform

      Typhoeus::Pool.release(easy)

      # tempfile 1
      expect(File.zero?(tempfile1.path)).to be(false)
      expect(File.read(tempfile1.path)).to match(/\s+foo\s+bar$/)
      expect(File.read(tempfile1.path)).to match(/\s+bar\s+foo$/)

      # tempfile2
      expect(File.zero?(tempfile2.path)).to be(false)
      expect(File.read(tempfile2.path)).to match(/\s+foo2\s+bar$/)
      expect(File.read(tempfile2.path)).to match(/\s+bar2\s+foo$/)
    end

    it "puts easy back into pool" do
      Typhoeus::Pool.release(easy)
      expect(Typhoeus::Pool.send(:easies)).to include(easy)
    end

    context "when the pool is full" do
      before { Typhoeus::Config.max_idle_easies = 1 }

      it "cleans up the extra easy instead of pooling it" do
        other = Ethon::Easy.new
        Typhoeus::Pool.release(easy)
        expect(other).to receive(:cleanup)

        Typhoeus::Pool.release(other)

        expect(Typhoeus::Pool.send(:easies)).to eq([easy])
      end
    end

    context "when pooling is disabled" do
      before { Typhoeus::Config.max_idle_easies = 0 }

      it "cleans up instead of pooling" do
        expect(easy).to receive(:cleanup)

        Typhoeus::Pool.release(easy)

        expect(Typhoeus::Pool.send(:easies)).to be_empty
      end
    end

    context "when an unexpected error is raised" do
      before { allow(easy).to receive(:cookielist=).and_raise("boom") }

      it "re-raises instead of dropping the easy" do
        expect { Typhoeus::Pool.release(easy) }.to raise_error("boom")
      end
    end

    context "when max_idle_easies is nil" do
      before { Typhoeus::Config.max_idle_easies = nil }

      it "keeps every easy" do
        3.times { Typhoeus::Pool.release(Ethon::Easy.new) }

        expect(Typhoeus::Pool.send(:easies).size).to eq(3)
      end
    end

    context "when easy was created before a fork" do
      before do
        skip unless defined?(Ethon::Errors::ForkSafety)
        allow(easy).to receive(:cookielist=).and_raise(Ethon::Errors::ForkSafety.new)
      end

      it "drops the easy instead of raising" do
        expect { Typhoeus::Pool.release(easy) }.not_to raise_error
        expect(Typhoeus::Pool.send(:easies)).not_to include(easy)
      end
    end

    context "when libcurl does not support cookies" do
      before do
        skip unless defined?(Ethon::Errors::UnsupportedOption)
        allow(easy).to receive(:cookielist=).and_raise(
          Ethon::Errors::UnsupportedOption.new(:cookielist)
        )
      end

      it "still resets and pools the easy" do
        expect(easy).to receive(:reset).and_call_original

        expect { Typhoeus::Pool.release(easy) }.not_to raise_error
        expect(Typhoeus::Pool.send(:easies)).to include(easy)
      end
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
          queue = Queue.new
          (0..9).map do |n|
            Thread.new do
              queue.enq(Typhoeus::Pool.get)
            end
          end.map(&:join)

          array = Array.new(queue.size) { queue.pop }
          expect(array.uniq.size).to eq(10)
        end
      end
    end

    context "when forked" do
      let(:easy) { double("easy") }
      let(:forked_easy) { double("forked easy") }

      before do
        allow(Ethon::Easy).to receive(:new).and_return(forked_easy)
        allow(Process).to receive(:pid).and_return(1)
        Typhoeus::Pool.send(:easies) << easy
        allow(Process).to receive(:pid).and_return(2)
      end

      after do
        allow(Process).to receive(:pid).and_call_original
        Typhoeus::Pool.instance_variable_set(:@pid, Process.pid)
      end

      it "creates" do
        expect(Typhoeus::Pool.get).to be(forked_easy)
      end
    end

    context "when forked while the pool lock is held" do
      let(:forked_easy) { double("forked easy") }
      let(:old_mutex) { Typhoeus::Pool.instance_variable_get(:@mutex) }

      before do
        allow(Ethon::Easy).to receive(:new).and_return(forked_easy)
        old_mutex.lock
        allow(Process).to receive(:pid).and_return(Process.pid + 1)
      end

      after do
        old_mutex.unlock if old_mutex.owned?
        allow(Process).to receive(:pid).and_call_original
        Typhoeus::Pool.instance_variable_set(:@pid, Process.pid)
      end

      it "does not block on the inherited mutex" do
        getter = Thread.new { Typhoeus::Pool.get }

        unless getter.join(5)
          getter.kill
          raise "Pool.get blocked on the mutex inherited from the parent process"
        end

        expect(getter.value).to be(forked_easy)
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

    it "releases the easy when the block raises" do
      easy = Ethon::Easy.new
      allow(Typhoeus::Pool).to receive(:get).and_return(easy)
      expect(Typhoeus::Pool).to receive(:release).with(easy)

      expect { Typhoeus::Pool.with_easy { raise "boom" } }.to raise_error("boom")
    end
  end
end
