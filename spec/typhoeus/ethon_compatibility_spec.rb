# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

# Coverage for the behavior Typhoeus relies on from Ethon 0.19. The
# capability checks keep the suite green against Ethon 0.18 until it is
# released.
describe "Ethon 0.19 compatibility" do
  let(:base_url) { TestServer.url }

  context "when multipart PUT is supported", :if => Ethon::Easy.method_defined?(:error_message) do
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

    context "when Ethon validates option values" do
      before do
        unless ethon_validates_option_values?
          skip "Ethon 0.18 does not validate enum and bitmask values"
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
  end

  describe "Multi connection options" do
    it "accepts max_total_connections" do
      hydra = Typhoeus::Hydra.new(:max_total_connections => 1)
      requests = 2.times.map { |i| Typhoeus::Request.new("#{base_url}/max-total/#{i}") }
      requests.each { |request| hydra.queue(request) }
      hydra.run

      expect(requests.map { |request| request.response.code }).to eq([200, 200])
    end

    context "when the connection options are available",
      :if => Ethon::Multi.method_defined?(:max_host_connections=) do
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

  # Ethon 0.19 rejects unknown enum and bitmask values. Probe the behavior so
  # the suite stays green against Ethon 0.18, which silently accepts them.
  def ethon_validates_option_values?
    easy = Ethon::Easy.new
    begin
      easy.sslversion = :invalid
      false
    ensure
      easy.cleanup
    end
  rescue Ethon::Errors::InvalidValue
    true
  end
end
