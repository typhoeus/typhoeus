# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request do
  let(:base_url) { TestServer.host }
  let(:options) do
    {
      verbose: true,
      headers: { "User-Agent" => "Fubar", "Expect" => "" },
      maxredirs: 50
    }
  end
  let(:request) { Typhoeus::Request.new(base_url, options) }

  describe ".url" do
    context "when no parameters" do
      it "returns base_url" do
        expect(request.url).to eq(request.base_url)
      end
    end

    context "when parameters" do
      let(:options) { {:params => {:a => 1}} }

      it "returns full url" do
        expect(request.url).to eq("#{request.base_url}?a=1")
      end
    end

    it "pushes an easy back into the pool" do
      easy = double.as_null_object
      allow(Typhoeus::Pool).to receive(:get).and_return(easy)
      expect(Typhoeus::Pool).to receive(:release).with(easy, :cleanup => false)
      request.url
    end

    it "keeps the read callback option" do
      request.options[:set_read_callback] = "body"
      request.url

      expect(request.options[:set_read_callback]).to eq("body")
    end

    it "does not apply unrelated request options" do
      request = Typhoeus::Request.new(base_url, :not_an_option => 1)

      expect(request.url).to eq(base_url)
    end

    it "only passes URL related options to Ethon" do
      easy = double.as_null_object
      allow(Typhoeus::Pool).to receive(:get).and_return(easy)
      allow(Typhoeus::Pool).to receive(:release)
      request = Typhoeus::Request.new(
        base_url,
        :params => { :a => 1 },
        :params_encoding => :rack,
        :escape => false,
        :headers => { "X-Test" => "1" }
      )

      expect(easy).to receive(:http_request).with(
        base_url,
        :get,
        hash_including(
          :params => { :a => 1 },
          :params_encoding => :rack,
          :escape => false
        )
      )
      request.url
    end
  end

  describe ".new" do
    it "stores base_url" do
      expect(request.base_url).to eq(base_url)
    end

    it "stores options" do
      expect(request.options).to eq(options)
    end

    it "stores original options" do
      expect(request.original_options).to eq(options)
      expect(request.original_options).to_not be(request.options)
    end

    it "sets defaults" do
      expect(request.options[:headers]['User-Agent']).to be
    end
  end

  describe "set_defaults" do
    context "when header with user agent" do
      let(:options) { {:headers => {'User-Agent' => "Custom"} } }

      it "doesn't modify user agent" do
        expect(request.options[:headers]['User-Agent']).to eq("Custom")
      end
    end

    context "when header without user agent" do
      let(:options) { {:headers => {} } }

      it "add user agent" do
        agent = request.options[:headers]['User-Agent']
        expect(agent).to eq(Typhoeus::USER_AGENT)
      end
    end

    context "when Config.user_agent set" do
      before { Typhoeus.configure { |config| config.user_agent = "Default" } }
      after { Typhoeus.configure { |config| config.user_agent = nil } }

      context "with headers" do
        let(:options) { {:headers => { "User-Agent" => "Fubar" } } }

        it "uses the request options' user agent" do
          expect(request.options[:headers]["User-Agent"]).to eq("Fubar")
        end
      end

      context "without headers" do
        let(:options) { {:headers => {} } }

        it "uses the global options' user agent" do
          expect(request.options[:headers]["User-Agent"]).to eq("Default")
        end
      end
    end

    context "when Config.verbose set" do
      before { Typhoeus.configure { |config| config.verbose = true} }
      after { Typhoeus.configure { |config| config.verbose = false} }

      it "respects" do
        expect(request.options[:verbose]).to be_truthy
      end
    end

    context "when Config.timeout set" do
      before { Typhoeus.configure { |config| config.timeout = 10 } }
      after { Typhoeus.configure { |config| config.timeout = nil } }

      it "respects configuration" do
        expect(request.options[:timeout]).to eq(10)
      end
    end

    context "when Config.connecttimeout set" do
      before { Typhoeus.configure { |config| config.connecttimeout = 10 } }
      after { Typhoeus.configure { |config| config.connecttimeout = nil } }

      it "respects configuration" do
        expect(request.options[:connecttimeout]).to eq(10)
      end
    end

    context "when maxredirs" do
      context "when not set" do
        it "defaults to 50" do
          expect(request.options[:maxredirs]).to be(50)
        end
      end

      context "when set" do
        let(:options) { {:maxredirs => 1} }

        it "respects" do
          expect(request.options[:maxredirs]).to be(1)
        end
      end
    end

    context "when SSL_CERT_FILE is set" do
      before do
        @old_ssl_cert_file = ENV["SSL_CERT_FILE"]
        ENV["SSL_CERT_FILE"] = "/tmp/ca.pem"
      end

      after { ENV["SSL_CERT_FILE"] = @old_ssl_cert_file }

      it "sets cainfo" do
        expect(request.options[:cainfo]).to eq("/tmp/ca.pem")
      end

      context "when cainfo is set" do
        let(:options) { {:cainfo => "/tmp/other.pem"} }

        it "respects the option" do
          expect(request.options[:cainfo]).to eq("/tmp/other.pem")
        end
      end
    end

    context "when SSL_CERT_DIR is set" do
      before do
        @old_ssl_cert_dir = ENV["SSL_CERT_DIR"]
        ENV["SSL_CERT_DIR"] = "/tmp/certs"
      end

      after { ENV["SSL_CERT_DIR"] = @old_ssl_cert_dir }

      it "sets capath" do
        expect(request.options[:capath]).to eq("/tmp/certs")
      end
    end

    context "when Config.proxy set" do
      before { Typhoeus.configure { |config| config.proxy = "http://proxy.internal" } }
      after { Typhoeus.configure { |config| config.proxy = nil } }

      it "respects" do
        expect(request.options[:proxy]).to eq("http://proxy.internal")
      end

      context "when option proxy set" do
        let(:options) { {:proxy => nil} }

        it "does not override" do
          expect(request.options[:proxy]).to be_nil
        end
      end
    end
  end

  describe "#eql?" do
    context "when another class" do
      let(:other) { "" }

      it "returns false" do
        expect(request).to_not eql other
      end
    end

    context "when same class" do
      let(:other) { Typhoeus::Request.new("base_url", options) }

      context "when other base_url" do
        it "returns false" do
          expect(request).to_not eql other
        end
      end

      context "when same base_url and other options" do
        let(:other) { Typhoeus::Request.new(base_url, {}) }

        it "returns false" do
          expect(request).to_not eql other
        end
      end


      context "when same base_url and options" do
        context "when same order" do
          let(:other) { Typhoeus::Request.new(base_url, options) }

          it "returns true" do
            expect(request).to eql other
          end
        end

        context "when different order" do
          let(:other_options) {
            {:headers => { 'User-Agent' => "Fubar", 'Expect' => ""}, :verbose => true }
          }
          let(:other) { Typhoeus::Request.new(base_url, other_options)}

          it "returns true" do
            expect(request).to eql other
          end
        end
      end
    end
  end

  describe "#hash" do
    context "when request.eql?(other)" do
      context "when different order" do
        let(:other_options) {
          {:headers => { 'User-Agent' => "Fubar", 'Expect' => "" }, :verbose => true }
        }
        let(:other) { Typhoeus::Request.new(base_url, other_options)}

        it "has same hashes" do
          expect(request.hash).to eq(other.hash)
        end
      end

      context "when same order" do
        let(:other) { Typhoeus::Request.new(base_url, options) }

        it "has same hashes" do
          expect(request.hash).to eq(other.hash)
        end
      end

      context "when hashes with different orders are contained in arrays" do
        let(:request) { Typhoeus::Request.new(base_url, :params => [{:b => 2, :a => 1}]) }
        let(:other) { Typhoeus::Request.new(base_url, :params => [{:a => 1, :b => 2}]) }
        it "has different hashes" do
          expect(request.hash).to eq(other.hash)
        end
      end
    end

    context "when not request.eql?(other)" do
      let(:request) { Typhoeus::Request.new(base_url, :params => {:foo => 'bar'}) }
      let(:other) { Typhoeus::Request.new(base_url, :params => {:foo => 'baz'}) }

      it "has different hashes" do
        expect(request.hash).to_not eq(other.hash)
      end
    end
  end

  describe '#cache_key' do
    context 'with different cache store instances' do
      let(:request_with_cache) do
        proc { |cache_store| described_class.new(base_url, :cache => cache_store) }
      end

      let(:request_1) { request_with_cache.call(MemoryCache.new) }
      let(:request_2) { request_with_cache.call(MemoryCache.new) }

      it 'returns the same cache key' do
        expect(request_1.options[:cache]).to_not eq(request_2.options[:cache])
        expect(request_1.cache_key).to eq(request_2.cache_key)
      end
    end

    context 'with different cache ttls' do
      let(:request_1) { described_class.new(base_url, :cache_ttl => 10) }
      let(:request_2) { described_class.new(base_url, :cache_ttl => 60) }

      it 'returns the same cache key' do
        expect(request_1.cache_key).to eq(request_2.cache_key)
      end
    end

    context 'with different options' do
      let(:request_1) { described_class.new(base_url, :params => { :a => 1 }) }
      let(:request_2) { described_class.new(base_url, :params => { :a => 2 }) }

      it 'returns different cache keys' do
        expect(request_1.cache_key).to_not eq(request_2.cache_key)
      end
    end

    context 'with values that stringify the same' do
      let(:request_1) { described_class.new(base_url, :params => { :filter => ["b", "c"] }) }
      let(:request_2) { described_class.new(base_url, :params => { :filter => '["b", "c"]' }) }

      it 'returns different cache keys' do
        expect(request_1.cache_key).to_not eq(request_2.cache_key)
      end
    end

    context 'with an array and a hash' do
      let(:request_1) { described_class.new(base_url, :body => { :a => [] }) }
      let(:request_2) { described_class.new(base_url, :body => { :a => {} }) }

      it 'returns different cache keys' do
        expect(request_1.cache_key).to_not eq(request_2.cache_key)
      end
    end

    context 'with keys that stringify the same' do
      let(:request_1) { described_class.new(base_url, :params => { :a => 1, 'a' => 2 }) }
      let(:request_2) { described_class.new(base_url, :params => { 'a' => 2, :a => 1 }) }

      it 'returns the same cache key' do
        expect(request_1.cache_key).to eq(request_2.cache_key)
      end
    end
  end

  describe "#encoded_body" do
    let(:request) {
      Typhoeus::Request.new("www.example.com",:body => {:a => 1})
    }

    it "returns encoded body" do
      expect(request.encoded_body).to eq("a=1")
    end

    it "uses the request's params encoding" do
      request = Typhoeus::Request.new(
        "www.example.com",
        :method => :post,
        :body => { "a" => [1, 2] },
        :params_encoding => :rack
      )

      expect(request.encoded_body).to eq("a%5B%5D=1&a%5B%5D=2")
    end

    it "uses the request's escaping" do
      request = Typhoeus::Request.new(
        "www.example.com",
        :method => :post,
        :body => { "a" => "a b" },
        :escape => false
      )

      expect(request.encoded_body).to eq("a=a b")
    end

    it "escapes PUT bodies like Ethon does" do
      request = Typhoeus::Request.new(
        "www.example.com",
        :method => :put,
        :body => { "a" => "a b" },
        :escape => false
      )

      expect(request.encoded_body).to eq("a=a%20b")
    end

    it "matches the body sent for a PUT without escaping" do
      request = Typhoeus::Request.new(
        "#{TestServer.url}/encoded-body",
        :method => :put,
        :body => { "a" => "a b" },
        :escape => false
      )
      response = request.run

      expect(JSON.parse(response.body)["body"]).to eq(request.encoded_body)
    end

    it "matches the body sent for every params encoding" do
      cases = {
        :typhoeus => { "a" => "a b", "b" => [1, 2] },
        :rack => { "a" => "a b", "b" => [1, 2] },
        :multi => { "a" => "a b", "b" => "c d" },
        :none => { "a" => "a b", "b" => "c d" }
      }

      cases.each do |params_encoding, body|
        request = Typhoeus::Request.new(
          "#{TestServer.url}/encoded-body",
          :method => :post,
          :body => body,
          :params_encoding => params_encoding
        )
        response = request.run

        expect(JSON.parse(response.body)["body"]).to eq(request.encoded_body)
      end
    end
  end

end
