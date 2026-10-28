# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

# Coverage for the behavior Typhoeus relies on from Ethon 0.19.
describe "Ethon 0.19 compatibility" do
  let(:base_url) { TestServer.url }

  describe "multipart PUT" do
    it "sends the body as multipart/form-data" do
      file = Tempfile.new(["typhoeus", ".txt"])
      file.write("multipart put body")
      file.rewind

      response = Typhoeus.put("#{base_url}/file", :body => { :file => file })
      json = JSON.parse(response.body)

      expect(response.code).to eq(200)
      expect(json["request-method"]).to eq("PUT")
      expect(json["request-content-type"]).to start_with("multipart/form-data")
      expect(json["filename"]).to eq(File.basename(file.path))
      expect(json["content"]).to eq("multipart put body")
    ensure
      file.close!
    end
  end

  describe "option value translation" do
    it "passes enum and bitmask values through to Ethon" do
      request = Typhoeus::Request.new(
        base_url,
        :sslversion => :tlsv1_2,
        :httpauth => :basic,
        :proxytype => :http
      )
      factory = Typhoeus::EasyFactory.new(request, nil)
      easy = factory.easy

      begin
        expect(easy).to receive(:sslversion=).with(:tlsv1_2).and_call_original
        expect(easy).to receive(:httpauth=).with(:basic).and_call_original
        expect(easy).to receive(:proxytype=).with(:http).and_call_original
        factory.get
      ensure
        factory.release_easy(easy)
      end
    end

    it "raises InvalidValue for an invalid enum" do
      request = Typhoeus::Request.new(base_url, :sslversion => :invalid)

      expect { request.run }.to raise_error(Ethon::Errors::InvalidValue)
    end

    it "releases the easy when an invalid value raises" do
      request = Typhoeus::Request.new(base_url, :sslversion => :invalid)

      expect { request.run }.to raise_error(Ethon::Errors::InvalidValue)
      expect(Typhoeus::Pool.send(:easies)).not_to be_empty
    end
  end

  describe "resolve lists" do
    # Typhoeus cleans up easies that used a resolve list instead of pooling
    # them, which Ethon 0.19.0 rejected from on_complete.
    it "performs a request through a custom resolve list" do
      port = TestServer.port
      resolve = Ethon::Curl::Slist.new(
        Ethon::Curl::Slist.build(["typhoeus-resolve.invalid:#{port}:127.0.0.1"])
      )

      response = Typhoeus.get(
        "http://typhoeus-resolve.invalid:#{port}/",
        :resolve => resolve
      )

      expect(response.code).to eq(200)
      expect(response.return_code).to eq(:ok)
    end
  end

  describe "Multi connection options" do
    it "accepts max_total_connections" do
      hydra = Typhoeus::Hydra.new(:max_total_connections => 1)
      requests = 2.times.map { |i| Typhoeus::Request.new("#{base_url}/max-total/#{i}") }
      requests.each { |request| hydra.queue(request) }
      hydra.run

      expect(requests.map { |request| request.response.code }).to eq([200, 200])
    end

    {
      :max_host_connections => 1,
      :max_pipeline_length => 1,
      :content_length_penalty_size => 0,
      :chunk_length_penalty_size => 0
    }.each do |option, value|
      it "accepts #{option}" do
        hydra = Typhoeus::Hydra.new(option => value)
        request = Typhoeus::Request.new("#{base_url}/multi-#{option}")
        hydra.queue(request)
        hydra.run

        expect(request.response.code).to eq(200)
      end
    end
  end
end
