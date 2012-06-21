require 'spec_helper'

describe Typhoeus::Requests::Callbacks do
  let(:request) { Typhoeus::Request.new("fubar") }

  describe "#on_complete" do
    it "responds to" do
      request.should respond_to(:on_complete)
    end
  end

  describe "#complete" do
    before do
      request.on_complete {|r| String.new(r.url) }
      String.expects(:new).with(request.url)
    end

    it "executes block and passes self" do
      request.complete
    end
  end
end
