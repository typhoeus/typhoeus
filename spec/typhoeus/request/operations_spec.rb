require 'spec_helper'

describe Typhoeus::Request::Operations do
  let(:base_url) { "localhost:3001" }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new(base_url, options) }

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

    context "when invalid option" do
      let(:options) { { :fubar => true } }

      it "raises Ethon::Errors::InvalidOption" do
        expect{ request.run }.to raise_error(Ethon::Errors::InvalidOption)
      end
    end

    context "when option renamed" do
      let(:options) { { :follow_location => true } }

      it "raises Ethon::Errors::InvalidOption" do
        expect{ request.run }.to raise_error(Ethon::Errors::InvalidOption)
      end

      it "has hint for new option" do
        expect{ request.run }.to raise_error(/Please try followlocation instead of follow_location\./)
      end
    end

    context "when option removed" do
      let(:options) { { :cache_timout => 1 } }

      it "raises Ethon::Errors::InvalidOption" do
        expect{ request.run }.to raise_error(Ethon::Errors::InvalidOption)
      end

      it "has hint for removed option" do
        expect{ request.run }.to raise_error(/The option cache_timout was removed\./)
      end
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
