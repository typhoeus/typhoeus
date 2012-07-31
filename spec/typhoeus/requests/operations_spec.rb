require 'spec_helper'

describe Typhoeus::Requests::Operations do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }

  describe "#run" do
    let(:easy) { Ethon::Easy.new }
    before { Typhoeus.should_receive(:get_easy).and_return(easy) }

    it "grabs an easy" do
      request.run
    end

    it "generates settings" do
      easy.should_receive(:http_request)
      request.run
    end

    it "prepares" do
      easy.should_receive(:prepare)
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
      Typhoeus.should_receive(:release_easy)
      request.run
    end

    it "calls on_complete" do
      callback = mock(:call)
      callback.should_receive(:call)
      request.instance_variable_set(:@on_complete, [callback])
      request.run
    end

    it "returns a response" do
      expect(request.run).to be_a(Typhoeus::Response)
    end
  end
end
