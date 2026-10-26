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
end
