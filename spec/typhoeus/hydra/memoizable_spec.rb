# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Hydra::Memoizable do
  let(:base_url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(base_url) }

  describe "add" do
    context "when memoization activated" do
      before { Typhoeus::Config.memoize = true }

      context "when request new" do
        it "sets no response" do
          hydra.add(request)
          expect(request.response).to be_nil
        end

        it "doesn't call complete" do
          expect(request).to receive(:complete).never
          hydra.add(request)
        end
      end

      context "when request is still in flight" do
        let(:key) { rand(1_000_000).to_s }
        let(:requests) do
          2.times.map { Typhoeus::Request.new("localhost:3001/count/#{key}") }
        end

        it "issues one request and shares the response" do
          requests.each { |queued_request| hydra.queue(queued_request) }
          hydra.run

          expect(requests.map { |queued_request| queued_request.response.body }).to eq(["1", "1"])
        end
      end

      context "when request in memory" do
        let(:response) { Typhoeus::Response.new }
        before { hydra.memory[request] = response }

        it "finishes request" do
          expect(request).to receive(:finish).with(response, true)
          hydra.add(request)
        end

        context "when queued request" do
          let(:queued_request) { Typhoeus::Request.new(base_url) }

          it "dequeues" do
            hydra.queue(queued_request)
            expect(request).to receive(:finish).with(response, true)
            expect(queued_request).to receive(:finish).with(response, true)
            hydra.add(request)
          end
        end
      end
    end
  end

  describe "#run" do
    before { Typhoeus::Config.memoize = true }

    it "clears memory before starting" do
      hydra.memory[request] = Typhoeus::Response.new
      hydra.run
      expect(hydra.memory).to be_empty
    end

    it "keeps the callback handled_response" do
      request.on_complete { |_| :handled }
      hydra.queue(request)
      hydra.run

      expect(request.response.handled_response).to eq(:handled)
    end

    it "gives each request its own response" do
      url = "http://localhost:3001/count/memo-#{rand(1_000_000)}"
      first = Typhoeus::Request.new(url)
      second = Typhoeus::Request.new(url)
      first.on_complete { |_| :first }
      second.on_complete { |_| :second }
      hydra.queue(first)
      hydra.queue(second)
      hydra.run

      expect(first.response).to_not equal(second.response)
      expect(first.response.request).to equal(first)
      expect(second.response.request).to equal(second)
      expect(first.response.handled_response).to eq(:first)
      expect(second.response.handled_response).to eq(:second)
    end

    it "does not serve responses memoized by a direct run between runs" do
      url = "http://localhost:3001/count/memo-#{rand(1_000_000)}"
      first = Typhoeus::Request.new(url)
      hydra.queue(first)
      hydra.run
      first.run

      second = Typhoeus::Request.new(url)
      hydra.queue(second)
      hydra.run

      expect(second.response.body).to eq("3")
    end

    it "finishes waiting requests when the leader's callback raises" do
      url = "http://localhost:3001/count/memo-#{rand(1_000_000)}"
      leader = Typhoeus::Request.new(url)
      follower = Typhoeus::Request.new(url)
      leader.on_complete { |_| raise "boom" }
      hydra.queue(leader)
      hydra.queue(follower)

      expect { hydra.run }.to raise_error("boom")

      expect(follower.response).not_to be_nil
      expect(follower.response.request).to equal(follower)
    end

    it "clears memory when the run raises" do
      hydra.memory[request] = Typhoeus::Response.new
      allow(hydra).to receive(:multi).and_raise("boom")

      expect { hydra.run }.to raise_error("boom")
      expect(hydra.memory).to be_empty
    end
  end
end
