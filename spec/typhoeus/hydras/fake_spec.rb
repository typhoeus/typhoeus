require 'spec_helper'

describe Typhoeus::Hydras::Fake do
  let(:url) { "localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new() }
  let(:request) { Typhoeus::Request.new(url, {:method => :get}) }

  describe "queue" do
    context "when fake activated" do
      before { Typhoeus::Config.fake = true }
      after { Typhoeus::Config.fake = false }

      it "raises" do
        expect{hydra.queue(request)}.to raise_error(Typhoeus::Errors::NoStub)
      end
    end
  end
end
