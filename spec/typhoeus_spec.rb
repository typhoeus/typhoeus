# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus do
  before(:each) do
    Typhoeus.configure { |config| config.verbose = false; config.block_connection = false }
  end

  describe ".configure" do
    it "yields config" do
      Typhoeus.configure do |config|
        expect(config).to be_a(Typhoeus::Config)
      end
    end

    it "sets values config" do
      Typhoeus::Config.verbose = true
      expect(Typhoeus::Config.verbose).to be_truthy
    end
  end

  describe ".stub" do
    let(:base_url) { "www.example.com" }

    shared_examples "lazy response construction" do
      it "calls the block to construct a response when a request matches the stub" do
        expected_response = Typhoeus::Response.new
        Typhoeus.stub(base_url) do |request|
          expected_response
        end

        response = Typhoeus.get(base_url)

        expect(response).to be(expected_response)
      end
    end

    context "when no similar expectation exists" do
      include_examples "lazy response construction"

      it "returns expectation" do
        expect(Typhoeus.stub(base_url)).to be_a(Typhoeus::Expectation)
      end

      it "adds expectation" do
        Typhoeus.stub(:get, "")
        expect(Typhoeus::Expectation.all.size).to eq(1)
      end

      it "raises when the stub has no response" do
        Typhoeus.stub(base_url)

        expect { Typhoeus.get(base_url) }.to raise_error(
          Typhoeus::Errors::NoResponse,
          /No response defined for stub/
        )
      end
    end

    context "when similar expectation exists" do
      include_examples "lazy response construction"

      let(:expectation) { Typhoeus::Expectation.new(base_url) }
      before { Typhoeus::Expectation.all << expectation }

      it "returns expectation" do
        expect(Typhoeus.stub(base_url)).to be_a(Typhoeus::Expectation)
      end

      it "doesn't add expectation" do
        Typhoeus.stub(base_url)
        expect(Typhoeus::Expectation.all.size).to eq(1)
      end
    end

    context "when base_url is URI" do
      it "stubs and matches URI base_url" do
        uri = URI("https://example.com")
        expected_response = Typhoeus::Response.new(body: "stubbed")

        Typhoeus.stub(uri).and_return(expected_response)
        response = Typhoeus.get(uri)

        expect(response.body).to eq("stubbed")
      end
    end
  end

  describe ".before" do
    it "adds callback" do
      Typhoeus.before { true }
      expect(Typhoeus.before.size).to eq(1)
    end
  end

  describe ".with_connection" do
    it "executes block with block connection is false" do
      Typhoeus.with_connection { expect(Typhoeus::Config.block_connection).to be(false) }
    end

    it "unblocks the current thread" do
      Typhoeus::Config.block_connection = true

      Typhoeus.with_connection do
        expect(Typhoeus::Request.new("www.example.com").blocked?).to be(false)
      end
    end

    it "sets block connection back to previous value" do
      Typhoeus::Config.block_connection = true
      Typhoeus.with_connection {}
      expect(Typhoeus::Config.block_connection).to be(true)
    end

    it "returns result of block" do
      expect(Typhoeus.with_connection { "123" }).to eq("123")
    end

    it "sets block connection back when the block raises" do
      Typhoeus::Config.block_connection = true
      expect {
        Typhoeus.with_connection { raise "boom" }
      }.to raise_error("boom")
      expect(Typhoeus::Config.block_connection).to be(true)
    end

    it "does not unblock other threads" do
      Typhoeus::Config.block_connection = true
      entered = Queue.new
      release = Queue.new
      thread = Thread.new do
        Typhoeus.with_connection do
          entered << true
          release.pop
        end
      end

      begin
        entered.pop
        expect(Typhoeus::Request.new("www.example.com").blocked?).to be_truthy
      ensure
        release << true
        thread.join
      end
    end

    it "applies to fibers in the current thread" do
      Typhoeus::Config.block_connection = true

      blocked, stubs_disabled = Typhoeus.with_connection do
        Fiber.new do
          [Typhoeus.connection_blocked?, Typhoeus.stubs_disabled?]
        end.resume
      end

      expect(blocked).to be(false)
      expect(stubs_disabled).to be(true)
    end

    it "keeps the override when fibers leave out of order" do
      Typhoeus::Config.block_connection = true

      first = Fiber.new do
        Typhoeus.with_connection { Fiber.yield }
      end
      first.resume

      second = Fiber.new do
        Typhoeus.with_connection do
          Fiber.yield
          [Typhoeus.connection_blocked?, Typhoeus.stubs_disabled?]
        end
      end
      second.resume

      # The first fiber finishes while the second is still inside the block.
      first.resume

      expect(second.resume).to eq([false, true])
      expect(Typhoeus.connection_blocked?).to be(true)
      expect(Typhoeus.stubs_disabled?).to be_nil
    end

    it "restores the override only when nested calls finish" do
      Typhoeus::Config.block_connection = true

      Typhoeus.with_connection do
        Typhoeus.with_connection do
          expect(Typhoeus.stubs_disabled?).to be(true)
        end

        expect(Typhoeus.connection_blocked?).to be(false)
        expect(Typhoeus.stubs_disabled?).to be(true)
      end

      expect(Typhoeus.connection_blocked?).to be(true)
      expect(Typhoeus.stubs_disabled?).to be_nil
    end
  end

  describe "timeouts" do
    after { Typhoeus::Config.timeout = nil }

    it "prefers an explicit timeout_ms over timeout" do
      response = Typhoeus.get(
        "#{TestServer.url}/?delay=1",
        :timeout_ms => 100,
        :timeout => 5
      )

      expect(response).to be_timed_out
    end

    it "prefers timeout_ms over the configured timeout" do
      Typhoeus::Config.timeout = 5

      response = Typhoeus.get(
        "#{TestServer.url}/?delay=1",
        :timeout_ms => 100
      )

      expect(response).to be_timed_out
    end
  end

  [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
    describe ".#{name}" do
      let(:response) { Typhoeus::Request.method(name).call(TestServer.url) }

      it "returns ok" do
        expect(response.return_code).to eq(:ok)
      end

      unless name == :head
        it "makes #{name.to_s.upcase} requests" do
          expect(response.response_body).to include("\"REQUEST_METHOD\":\"#{name.to_s.upcase}\"")
        end
      end
    end
  end
end
