require 'spec_helper'

describe Typhoeus::EasyFu::Options do
  describe "#set_headers" do
    let(:headers) { { 'User-Agent' => "fubar\0" } }
    let(:request) { Typhoeus::Request.get("http://localhost:3001", { :headers => headers }) }

    it "sends them" do
      request.body.should include("fubar")
    end

    it "removes zero bytes from values" do
      request.body.should include("fubar\\\\0")
    end
  end
end
