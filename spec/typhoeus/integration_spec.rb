# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

describe "Typhoeus HTTP features" do
  let(:base_url) { TestServer.url }

  describe "redirections" do
    it "follows a redirect when followlocation is enabled" do
      response = Typhoeus.get("#{base_url}/redirect", :followlocation => true)

      expect(response.code).to eq(200)
      expect(response.redirect_count).to eq(1)
      expect(response.redirections.size).to eq(1)
      expect(response.redirections.first.headers["Location"]).to eq("#{base_url}/")
      expect(JSON.parse(response.body)["PATH_INFO"]).to eq("/")
    end

    it "runs on_headers for the final response" do
      codes = []
      request = Typhoeus::Request.new("#{base_url}/redirect", :followlocation => true)
      request.on_headers { |response| codes << response.code }

      request.run

      expect(codes).to eq([200])
    end

    it "returns the redirect when followlocation is disabled" do
      response = Typhoeus.get("#{base_url}/redirect")

      expect(response.code).to eq(302)
      expect(response.headers["Location"]).to end_with("/")
    end
  end

  describe "duplicate response headers" do
    it "exposes every value" do
      response = Typhoeus.get("#{base_url}/multiple-headers")

      expect(response.headers["Set-Cookie"]).to eq(["foo", "bar"])
    end
  end

  describe "basic authentication" do
    it "sends the user and password" do
      response = Typhoeus.get("#{base_url}/auth_basic/user/pass", :userpwd => "user:pass")

      expect(response.code).to eq(200)
    end

    it "reports unauthorized credentials" do
      response = Typhoeus.get("#{base_url}/auth_basic/user/pass", :userpwd => "user:wrong")

      expect(response.code).to eq(401)
      expect(response.headers["WWW-Authenticate"]).to include("Basic")
    end
  end

  describe "compression" do
    it "decompresses the response when accept_encoding is set" do
      response = Typhoeus.get("#{base_url}/gzipped", :accept_encoding => "gzip")

      expect(response.code).to eq(200)
      expect(response.headers["Content-Encoding"]).to eq("gzip")
      expect(JSON.parse(response.body)["PATH_INFO"]).to eq("/gzipped")
    end

    it "leaves the body compressed when the header is set directly" do
      response = Typhoeus.get(
        "#{base_url}/gzipped",
        :headers => { "Accept-Encoding" => "gzip" }
      )

      expect(response.body.byteslice(0, 2).bytes).to eq([0x1f, 0x8b])
      expect { JSON.parse(response.body) }.to raise_error(JSON::ParserError)
    end
  end

  describe "cookies" do
    it "persists cookies through the configured jar" do
      jar = Tempfile.new("typhoeus-cookies")
      jar.close

      Typhoeus.get(
        "#{base_url}/cookies-test",
        :cookiefile => jar.path,
        :cookiejar => jar.path
      )
      response = Typhoeus.get(
        "#{base_url}/",
        :cookiefile => jar.path,
        :cookiejar => jar.path
      )

      expect(JSON.parse(response.body)["HTTP_COOKIE"]).to include("foo=bar")
    ensure
      jar.close! if jar
    end
  end

  describe "file uploads" do
    it "posts a file as multipart/form-data" do
      file = Tempfile.new(["typhoeus", ".txt"])
      file.write("upload body")
      file.rewind

      response = Typhoeus.post("#{base_url}/file", :body => { :file => file })
      json = JSON.parse(response.body)

      expect(response.code).to eq(200)
      expect(json["filename"]).to eq(File.basename(file.path))
      expect(json["content"]).to eq("upload body")
      expect(json["request-content-type"]).to start_with("multipart/form-data")
    ensure
      file.close! if file
    end
  end

  describe "timeouts" do
    it "reports a timed out request" do
      response = Typhoeus.get("#{base_url}/slow", :timeout => 0.05)

      expect(response.timed_out?).to be(true)
      expect(response.success?).to be(false)
      expect(response.return_code).to eq(:operation_timedout)
    end
  end

  describe "callbacks" do
    it "runs on_failure for an HTTP error" do
      failures = []
      request = Typhoeus::Request.new("#{base_url}/fail_forever")
      request.on_failure { |response| failures << response }

      response = request.run

      expect(response.code).to eq(500)
      expect(failures).to eq([response])
    end

    it "yields chunks without buffering the response" do
      chunks = []
      request = Typhoeus::Request.new("#{base_url}/stream")
      request.on_body { |chunk, _| chunks << chunk }

      response = request.run

      expect(chunks).not_to be_empty
      expect(chunks.join).to include('"PATH_INFO":"/stream"')
      expect(response.body).to eq("")
      expect(response.code).to eq(200)
    end

    it "stops streaming when on_body returns :abort" do
      chunks = []
      request = Typhoeus::Request.new("#{base_url}/stream")
      request.on_body do |chunk, _|
        chunks << chunk
        :abort
      end

      response = request.run

      expect(chunks).not_to be_empty
      expect(response.body).to eq("")
    end
  end
end
