require 'spec_helper'

describe Typhoeus::EasyFactory do
  let(:base_url) { "http://localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 0) }
  let(:options) { {} }
  let(:request) { Typhoeus::Request.new(base_url, options) }
  let(:easy_factory) { described_class.new(request, hydra) }

  describe "#get" do
    context "when option[:cache_ttl]" do
      let(:options) { {:cache_ttl => 1} }

      it "creates Ethon::Easy" do
        expect(easy_factory.get).to be_a(Ethon::Easy)
      end
    end

    context "when invalid option" do
      let(:options) { {:invalid => 1} }

      it "reraises" do
        expect{ easy_factory.get }.to raise_error(Ethon::Errors::InvalidOption)
      end
    end

    context "when removed option" do
      let(:options) { {:cache_timeout => 1} }

      it "reraises with help" do
        expect{ easy_factory.get }.to raise_error(
          Ethon::Errors::InvalidOption, /The option cache_timeout was removed/
        )
      end
    end

    context "when changed option" do
      let(:options) { {:proxy_auth_method => 1} }

      it "reraises with help" do
        expect{ easy_factory.get }.to raise_error(
          Ethon::Errors::InvalidOption, /Please try proxyauth instead of proxy_auth_method/
        )
      end
    end

    context "when renamed option" do
      let(:options) { {:connect_timeout => 1} }

      it "warns" do
        easy_factory.should_receive(:warn).with(
          "Deprecated option connect_timeout. Please use connecttimeout instead."
        )
        easy_factory.get
      end

      it "passes correct option" do
        easy_factory.should_receive(:warn)
        easy_factory.easy.should_receive(:connecttimeout=).with(1)
        easy_factory.get
      end
    end
  end

  describe "#set_callback" do
    it "sets easy.on_complete callback" do
      easy_factory.easy.should_receive(:on_complete)
      easy_factory.send(:set_callback)
    end

    it "finishes request" do
      easy_factory.send(:set_callback)
      request.should_receive(:finish)
      easy_factory.easy.complete
    end

    it "resets easy" do
      easy_factory.send(:set_callback)
      easy_factory.easy.should_receive(:reset)
      easy_factory.easy.complete
    end

    it "pushes easy back into the pool" do
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
      expect(Typhoeus::Pool.send(:easies)).to include(easy_factory.easy)
    end

    it "adds next request" do
      easy_factory.hydra.instance_variable_set(:@queued_requests, [request])
      easy_factory.hydra.should_receive(:add).with(request)
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
    end
  end
end
