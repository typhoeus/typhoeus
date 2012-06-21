require 'spec_helper'

describe Typhoeus::Requests::Actions do
  [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
    describe ".#{name}" do
      let(:response) { Typhoeus::Request.method(name).call("http://localhost:3001", {}) }

      it "returns ok" do
        response.return_code.should eq(:ok)
      end

      unless name == :head
        it "makes #{name.to_s.upcase} requests" do
          response.response_body.should include("\"REQUEST_METHOD\":\"#{name.upcase}\"")
        end
      end
    end
  end
end
