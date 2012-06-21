require 'spec_helper'

describe Typhoeus::Requests::CacheKey do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }

  describe 'cache_key' do
    context "when cache_key_basis" do
      let(:cache_key_basis) { "basis" }
      before { request.cache_key_basis = cache_key_basis }

      it "uses cache_key_basis" do
        Digest::SHA1.expects(:hexdigest).with(cache_key_basis)
        request.cache_key
      end
    end

    context "when no cache key_basis" do
      it "uses url" do
        Digest::SHA1.expects(:hexdigest).with(url)
        request.cache_key
      end
    end
  end
end
