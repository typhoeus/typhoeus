# frozen_string_literal: true

module Typhoeus
  # Multipart form data support.
  module Multipart
    # A single part of a multipart form body.
    #
    # Wrap a body value to control the content type, and optionally the
    # filename, that Typhoeus sends for that field.
    #
    # @example A JSON field.
    #   Typhoeus::Multipart::Part.new(
    #     JSON.generate(:a => 1),
    #     content_type: "application/json"
    #   )
    #
    # @example A file with an explicit filename and content type.
    #   Typhoeus::Multipart::Part.new(
    #     File.open("photo.jpg"),
    #     filename: "avatar.png",
    #     content_type: "image/png"
    #   )
    #
    # @example An in-memory upload.
    #   Typhoeus::Multipart::Part.new(
    #     "file contents",
    #     filename: "notes.txt",
    #     content_type: "text/plain"
    #   )
    Part = Ethon::Multipart::Part
  end
end
