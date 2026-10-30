# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

describe "multipart parts" do
  let(:base_url) { TestServer.url }
  let(:part) { Typhoeus::Multipart::Part }

  it "is Ethon's part" do
    expect(part).to be(Ethon::Multipart::Part)
  end

  it "sends a content type for a non-file part" do
    response = Typhoeus.post(
      "#{base_url}/echo",
      :body => {
        :metadata => part.new('{"a":1}', :content_type => "application/json")
      }
    )
    body = JSON.parse(response.body)["body"]

    expect(response.code).to eq(200)
    expect(body).to include(
      %(name="metadata"\r\nContent-Type: application/json\r\n\r\n{"a":1})
    )
  end

  it "sends a different content type and filename for each part" do
    file = Tempfile.new(["typhoeus", ".txt"])
    file.write("file contents")
    file.rewind

    response = Typhoeus.post(
      "#{base_url}/echo",
      :body => {
        :filedata => part.new(
          '{"fileName":"hi.jpg"}',
          :content_type => "application/json"
        ),
        :file => part.new(
          file,
          :filename => "newName.jpg",
          :content_type => "image/png"
        )
      }
    )
    body = JSON.parse(response.body)["body"]

    expect(response.code).to eq(200)
    expect(body).to include(
      %(name="filedata"\r\nContent-Type: application/json\r\n\r\n{"fileName":"hi.jpg"})
    )
    expect(body).to include(
      %(name="file"; filename="newName.jpg"\r\nContent-Type: image/png)
    )
  ensure
    file.close! if file
  end

  it "overrides the filename and content type of a file part" do
    file = Tempfile.new(["typhoeus", ".txt"])
    file.write("file contents")
    file.rewind

    response = Typhoeus.post(
      "#{base_url}/file",
      :body => {
        :file => part.new(
          file,
          :filename => "report.txt",
          :content_type => "text/custom"
        )
      }
    )
    json = JSON.parse(response.body)

    expect(response.code).to eq(200)
    expect(json["filename"]).to eq("report.txt")
    expect(json["content-type"]).to eq("text/custom")
    expect(json["content"]).to eq("file contents")
  ensure
    file.close! if file
  end

  it "sends in-memory data as a file part when a filename is given" do
    response = Typhoeus.post(
      "#{base_url}/file",
      :body => {
        :file => part.new(
          "file contents",
          :filename => "note.txt",
          :content_type => "text/plain"
        )
      }
    )
    json = JSON.parse(response.body)

    expect(response.code).to eq(200)
    expect(json["filename"]).to eq("note.txt")
    expect(json["content-type"]).to eq("text/plain")
    expect(json["content"]).to eq("file contents")
  end

  describe "cache keys" do
    def cache_key(content_type)
      Typhoeus::Request.new(
        "www.example.com",
        :body => { :metadata => part.new("data", :content_type => content_type) }
      ).cache_key
    end

    it "includes the part metadata" do
      expect(cache_key("application/json")).not_to eq(cache_key("text/plain"))
    end
  end

  describe "#encoded_body" do
    it "falls back to the part value" do
      request = Typhoeus::Request.new(
        "www.example.com",
        :body => { :metadata => part.new("data", :content_type => "application/json") }
      )

      expect(request.encoded_body).to eq("metadata=data")
    end
  end
end
