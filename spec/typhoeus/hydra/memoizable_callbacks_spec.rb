# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Hydra::Memoizable do
  let(:hydra) { Typhoeus::Hydra.new }

  before { Typhoeus::Config.memoize = true }
  after { Typhoeus::Config.memoize = false }

  it "runs on_headers callbacks for a follower" do
    url = "#{TestServer.url}/count/memo-#{TestServer.next_id}"
    leader = Typhoeus::Request.new(url)
    follower = Typhoeus::Request.new(url)
    codes = []
    follower.on_headers { |response| codes << response.code }
    hydra.queue(leader)
    hydra.queue(follower)
    hydra.run

    expect(codes).to eq([200])
  end

  it "sets the follower on the response for header callbacks" do
    url = "#{TestServer.url}/count/memo-#{TestServer.next_id}"
    leader = Typhoeus::Request.new(url)
    follower = Typhoeus::Request.new(url)
    seen_request = nil
    follower.on_headers { |response| seen_request = response.request }
    hydra.queue(leader)
    hydra.queue(follower)
    hydra.run

    expect(seen_request).to be(follower)
  end

  it "does not memoize streaming requests" do
    url = "#{TestServer.url}/count/memo-#{TestServer.next_id}"
    requests = 2.times.map { Typhoeus::Request.new(url) }
    chunks = []
    requests.each_with_index do |request, index|
      request.on_body { |chunk, _| chunks << [index, chunk] }
      hydra.queue(request)
    end
    hydra.run

    expect(requests.map { |request| request.response.body }).to eq(["", ""])
    expect(chunks.map(&:first).sort).to eq([0, 1])
  end
end
