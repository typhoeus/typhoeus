require 'spec_helper'

describe Typhoeus::Requests::Operations do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }

  describe "#run" do
    let(:easy) { Ethon::Easy.new }
    before { Typhoeus.expects(:get_easy).returns(easy) }

    it "grabs an easy" do
      request.run
    end

    it "generates settings" do
      easy.expects(:http_request)
      request.run
    end

    it "prepares" do
      easy.expects(:prepare)
      request.run
    end

    it "performs" do
      easy.expects(:perform)
      request.run
    end

    it "sets response" do
      request.run
      request.response.should be
    end

    it "releases easy" do
      Typhoeus.expects(:release_easy)
      request.run
    end

    it "calls on_complete" do
      request.instance_variable_set(:@on_complete, [mock(:call)])
      request.run
    end

    it "returns a response" do
      request.run.should be_a(Typhoeus::Response)
    end
  end
end
