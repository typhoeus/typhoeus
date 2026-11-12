# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Hydra do
  let(:base_url) { TestServer.host }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#new" do
    let(:options) { {:pipelining => true} }

    it "does not create a multi until it is needed" do
      expect(Ethon::Multi).not_to receive(:new)
      hydra
    end

    it "passes options to multi" do
      expect(Ethon::Multi).to receive(:new).with(options)
      hydra.multi
    end

    it "does not take later changes to the options" do
      options = {}
      hydra = Typhoeus::Hydra.new(options)
      options[:pipelining] = true

      expect(Ethon::Multi).to receive(:new).with({})
      hydra.multi
    end

    it "creates a multi on first use" do
      hydra = Typhoeus::Hydra.new

      expect(hydra.multi).to be_a(Ethon::Multi)
      expect(hydra.multi).to be(hydra.multi)
    end

    context "when max_concurrency is zero" do
      let(:options) { { :max_concurrency => 0 } }

      it "raises" do
        expect { hydra }.to raise_error(ArgumentError, /max_concurrency/)
      end
    end

    context "when max_concurrency is negative" do
      let(:options) { { :max_concurrency => -1 } }

      it "raises" do
        expect { hydra }.to raise_error(ArgumentError, /max_concurrency/)
      end
    end

    context "when max_concurrency is not set" do
      let(:options) { {} }

      it "defaults to 200" do
        expect(hydra.max_concurrency).to eq(200)
      end
    end

    context "when max_concurrency is set after creation" do
      let(:options) { {} }

      it "raises for zero" do
        expect { hydra.max_concurrency = 0 }.to raise_error(ArgumentError, /max_concurrency/)
      end

      it "raises for a negative value" do
        expect { hydra.max_concurrency = -1 }.to raise_error(ArgumentError, /max_concurrency/)
      end

      it "accepts a numeric string" do
        hydra.max_concurrency = "2"

        expect(hydra.max_concurrency).to eq(2)
      end

      it "rejects a non-numeric string" do
        expect { hydra.max_concurrency = "many" }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#hydra" do
    after { Thread.current[:typhoeus_hydra] = nil }

    it "returns a hydra" do
      expect(Typhoeus::Hydra.hydra).to be_a(Typhoeus::Hydra)
    end

    it "returns the same hydra in the same thread" do
      expect(Typhoeus::Hydra.hydra).to be(Typhoeus::Hydra.hydra)
    end

    it "returns a different hydra in another thread" do
      current = Typhoeus::Hydra.hydra
      other = Thread.new { Typhoeus::Hydra.hydra }.value

      expect(other).not_to be(current)
    end

    it "returns a hydra stored in a new thread" do
      stored = Typhoeus::Hydra.new
      returned = Thread.new do
        Thread.current[:typhoeus_hydra] = stored
        Typhoeus::Hydra.hydra
      end.value

      expect(returned).to be(stored)
    end

    it "does not warn when returning a hydra that other code stored" do
      Thread.current[:typhoeus_hydra] = Typhoeus::Hydra.new
      verbose = $VERBOSE
      $VERBOSE = true

      expect { Typhoeus::Hydra.hydra }.not_to output.to_stderr
    ensure
      $VERBOSE = verbose
    end

    it "returns a new hydra in a forked child" do
      skip "fork is not available on this platform" unless Process.respond_to?(:fork)
      parent_hydra = Typhoeus::Hydra.hydra
      parent_hydra.max_concurrency = 3
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          child_hydra = Typhoeus::Hydra.hydra
          writer.write([
            child_hydra.equal?(parent_hydra) ? "inherited" : "new",
            child_hydra.equal?(Typhoeus::Hydra.hydra) ? "memoized" : "not memoized",
            child_hydra.max_concurrency
          ].join(", "))
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("new, memoized, 3")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
      expect(Typhoeus::Hydra.hydra).to be(parent_hydra)
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "returns a new hydra in a process forked from a forked child" do
      skip "fork is not available on this platform" unless Process.respond_to?(:fork)
      Typhoeus::Hydra.hydra
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          child_hydra = Typhoeus::Hydra.hydra
          grandchild = fork do
            writer.write(Typhoeus::Hydra.hydra.equal?(child_hydra) ? "inherited" : "new")
            writer.close
          end
          Process.wait(grandchild)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("new")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "returns a hydra stored in a forked child" do
      skip "fork is not available on this platform" unless Process.respond_to?(:fork)
      parent_hydra = Typhoeus::Hydra.hydra
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          stored = Typhoeus::Hydra.new
          Thread.current[:typhoeus_hydra] = stored
          writer.write(Typhoeus::Hydra.hydra.equal?(stored) ? "stored" : "replaced")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("stored")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
      expect(Typhoeus::Hydra.hydra).to be(parent_hydra)
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "returns a hydra stored before a fork in the forked child" do
      skip "fork is not available on this platform" unless Process.respond_to?(:fork)
      stored = Typhoeus::Hydra.new
      Thread.current[:typhoeus_hydra] = stored
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          writer.write(Typhoeus::Hydra.hydra.equal?(stored) ? "stored" : "replaced")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("stored")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end

  describe "#dequeue" do
    it "adds the next queued request" do
      request = Typhoeus::Request.new(base_url)
      hydra.queue(request)
      expect(hydra).to receive(:add).with(request)

      hydra.dequeue
    end

    it "does nothing without a queued request" do
      expect(hydra).not_to receive(:add)

      hydra.dequeue
    end
  end

  describe "#add" do
    it "sets the hydra on the request" do
      Typhoeus.stub(base_url).and_return(Typhoeus::Response.new)
      request = Typhoeus::Request.new(base_url)

      hydra.add(request)

      expect(request.hydra).to be(hydra)
    end
  end

  describe "#run" do
    it "finishes when a discarded easy cannot be cleaned up" do
      Typhoeus::Config.max_idle_easies = 0
      easy = Ethon::Easy.new
      allow(Typhoeus::Pool).to receive(:get).and_return(easy)
      allow(easy).to receive(:cleanup).and_raise(
        Ethon::Errors::EthonError.new("Easy is currently completing")
      )
      request = Typhoeus::Request.new(TestServer.url)
      hydra.queue(request)

      expect { hydra.run }.not_to raise_error

      expect(request.response.code).to eq(200)
    end
  end
end
