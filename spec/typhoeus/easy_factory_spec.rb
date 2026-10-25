# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::EasyFactory do
  let(:base_url) { "http://localhost:3001" }
  let(:hydra) { Typhoeus::Hydra.new(:max_concurrency => 1) }
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
    
    context "timeouts" do
      it "sets nosignal to true by default" do
        expect(easy_factory.easy).to receive(:http_request).with(anything(), anything(), hash_including(:nosignal => true))
        easy_factory.get
      end

      context "when timeout is not a whole number and timeout_ms is not set" do
        let(:options) { {:timeout => 0.1} }
        it "ceils timeout and sets timeout_ms" do
          expect(easy_factory.easy).to receive(:http_request).with(anything(), anything(), hash_including(:timeout_ms => 100, :timeout => 1))
          easy_factory.get
        end
      end

      context "when timeout is not a whole number and timeout_ms is set" do
        let(:options) { {:timeout => 0.1, :timeout_ms => 123} }
        it "ceils timeout and does not change timeout_ms" do
          expect(easy_factory.easy).to receive(:http_request).with(anything(), anything(), hash_including(:timeout_ms => 123, :timeout => 1))
          easy_factory.get
        end
      end

      context "when connecttimeout is not a whole number and connecttimeout_ms is not set" do
        let(:options) { {:connecttimeout => 0.1} }
        it "ceils connecttimeout and sets connecttimeout_ms" do
          expect(easy_factory.easy).to receive(:http_request).with(anything(), anything(), hash_including(:connecttimeout_ms => 100, :connecttimeout => 1))
          easy_factory.get
        end
      end

      context "when connecttimeout is not a whole number and connecttimeout_ms is set" do
        let(:options) { {:connecttimeout => 0.1, :connecttimeout_ms => 123} }
        it "ceils connecttimeout and does not change connecttimeout_ms" do
          expect(easy_factory.easy).to receive(:http_request).with(anything(), anything(), hash_including(:connecttimeout_ms => 123, :connecttimeout => 1))
          easy_factory.get
        end
      end


    end

    context "when timeouts are not numeric" do
      let(:options) { { :timeout => "1" } }

      it "raises a helpful error" do
        expect { easy_factory.get }.to raise_error(ArgumentError, /timeout.*must be a number/)
      end

      it "releases the easy" do
        expect(Typhoeus::Pool).to receive(:release).with(anything, :cleanup => false)
        expect { easy_factory.get }.to raise_error(ArgumentError)
      end

      context "when timeout_ms" do
        let(:options) { { :timeout_ms => "100" } }

        it "raises a helpful error" do
          expect { easy_factory.get }.to raise_error(ArgumentError, /timeout_ms.*must be a number/)
        end
      end

      context "when connecttimeout" do
        let(:options) { { :connecttimeout => false } }

        it "raises a helpful error" do
          expect { easy_factory.get }.to raise_error(ArgumentError, /connecttimeout.*must be a number/)
        end
      end

      context "when connecttimeout_ms" do
        let(:options) { { :connecttimeout_ms => "100" } }

        it "raises a helpful error" do
          expect { easy_factory.get }.to raise_error(ArgumentError, /connecttimeout_ms.*must be a number/)
        end
      end

      context "when timeout_ms is nil" do
        let(:options) { { :timeout_ms => nil, :connecttimeout_ms => nil } }

        it "ignores the option" do
          expect { easy_factory.get }.not_to raise_error
        end
      end
    end

    context "when request has a read callback body" do
      let(:options) { {:set_read_callback => "body"} }

      it "keeps the option" do
        easy_factory.get
        expect(request.options[:set_read_callback]).to eq("body")
      end
    end

    context "when setting callbacks fails" do
      let(:easy) { Ethon::Easy.new }

      before do
        allow(Typhoeus::Pool).to receive(:get).and_return(easy)
        allow(easy_factory).to receive(:set_callback).and_raise("callback setup failed")
      end

      it "releases the easy" do
        expect(Typhoeus::Pool).to receive(:release).with(easy, :cleanup => false)
        expect { easy_factory.get }.to raise_error("callback setup failed")
      end

      it "marks the easy as released" do
        expect { easy_factory.get }.to raise_error("callback setup failed")
        expect(easy_factory.released?).to be(true)
      end
    end

    context "when invalid option" do
      let(:options) { {:invalid => 1} }

      it "reraises" do
        expect{ easy_factory.get }.to raise_error(Ethon::Errors::InvalidOption)
      end

      it "releases easy" do
        expect { easy_factory.get }.to raise_error(Ethon::Errors::InvalidOption)
        expect(Typhoeus::Pool.send(:easies)).to include(easy_factory.easy)
      end

      it "keeps the original error when the message cannot be parsed" do
        error = Ethon::Errors::InvalidOption.new("x")
        allow(error).to receive(:message).and_return("invalid option")
        expect(easy_factory.easy).to receive(:http_request).and_raise(error)

        expect { easy_factory.get }.to raise_error(Ethon::Errors::InvalidOption)
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
        expect(easy_factory).to receive(:warn).with(
          "Deprecated option connect_timeout. Please use connecttimeout instead."
        )
        easy_factory.get
      end

      it "passes correct option" do
        expect(easy_factory).to receive(:warn)
        expect(easy_factory.easy).to receive(:connecttimeout=).with(1)
        easy_factory.get
      end
    end
  end

  describe "#release_easy" do
    let(:easy) { double("easy") }

    context "when request used resolve" do
      let(:options) { {:resolve => "example.com:80:127.0.0.1"} }

      it "cleans the easy up instead of pooling it" do
        expect(Typhoeus::Pool).to receive(:release).with(easy, :cleanup => true)
        easy_factory.release_easy(easy)
      end
    end

    context "when request did not use resolve" do
      it "releases the easy to the pool" do
        expect(Typhoeus::Pool).to receive(:release).with(easy, :cleanup => false)
        easy_factory.release_easy(easy)
      end
    end
  end

  describe "#set_callback" do
    it "sets easy.on_progress callback when an on_progress callback is provided" do
      request.on_progress { 1 }
      expect(easy_factory.easy).to receive(:on_progress)
      easy_factory.send(:set_callback)
    end

    it "sets easy.on_progress callback when a global on_progress callback is provided" do
      Typhoeus.on_progress { 1 }
      expect(easy_factory.easy).to receive(:on_progress)
      easy_factory.send(:set_callback)
    end

    it "sets easy.on_progress callback for global and local callbacks" do
      Typhoeus.on_progress { 1 }
      request.on_progress { 2 }
      expect(easy_factory.easy).to receive(:on_progress).twice
      easy_factory.send(:set_callback)
    end

    it "sets easy.on_complete callback" do
      expect(easy_factory.easy).to receive(:on_complete)
      easy_factory.send(:set_callback)
    end

    it "finishes request" do
      easy_factory.send(:set_callback)
      expect(request).to receive(:finish)
      easy_factory.easy.complete
    end

    it "resets easy" do
      easy_factory.send(:set_callback)
      expect(easy_factory.easy).to receive(:reset)
      easy_factory.easy.complete
    end

    it "pushes easy back into the pool" do
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
      expect(Typhoeus::Pool.send(:easies)).to include(easy_factory.easy)
    end

    it "releases easy when finishing raises" do
      easy_factory.send(:set_callback)
      allow(request).to receive(:finish).and_raise("boom")
      expect(Typhoeus::Pool).to receive(:release)
      expect { easy_factory.easy.complete }.to raise_error("boom")
    end

    it "adds next request" do
      easy_factory.hydra.instance_variable_set(:@queued_requests, [request])
      expect(easy_factory.hydra).to receive(:add).with(request)
      easy_factory.send(:set_callback)
      easy_factory.easy.complete
    end
  end
end
