require 'spec_helper'

describe Typhoeus::Request::Operations do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new(base_url, options) }

  describe "#run" do
    let(:easy) { Ethon::Easy.new }
    before { Typhoeus::Pool.should_receive(:get).and_return(easy) }

    it "grabs an easy" do
      request.run
    end

    it "generates settings" do
      easy.should_receive(:http_request)
      request.run
    end

    it "performs" do
      easy.should_receive(:perform)
      request.run
    end

    it "sets response" do
      request.run
      expect(request.response).to be
    end

    it "releases easy" do
      Typhoeus::Pool.should_receive(:release)
      request.run
    end

    it "calls on_complete" do
      callback = double(:call)
      callback.should_receive(:call)
      request.instance_variable_set(:@on_complete, [callback])
      request.run
    end

    it "returns a response" do
      expect(request.run).to be_a(Typhoeus::Response)
    end
  end

  describe "#finish" do
    let(:response) { Typhoeus::Response.new }

    it "assigns response" do
      request.finish(response)
      expect(request.response).to be(response)
    end

    it "assigns request to response" do
      request.finish(response)
      expect(request.response.request).to be(request)
    end

    it "executes callbacks" do
      request.should_receive(:execute_callbacks)
      request.finish(response)
    end

    it "returns response" do
      expect(request.finish(response)).to be(response)
    end
  end
end
