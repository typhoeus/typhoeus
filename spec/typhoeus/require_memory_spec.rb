# frozen_string_literal: true

require "spec_helper"
require "rbconfig"

describe "require 'typhoeus' memory usage" do
  # Retained Ruby heap memory that requiring typhoeus may add. The baseline
  # includes Ethon, libcurl bindings, and Rack. The headroom catches an
  # accidentally eager-loaded dependency without making Ruby version
  # accounting differences fail the build.
  MAX_RETAINED_BYTES = 4 * 1024 * 1024

  it "retains less than 4 MB" do
    skip "ObjectSpace.memsize_of_all is not available on JRuby" if RUBY_ENGINE == "jruby"

    script = <<~'RUBY'
      require "objspace"
      limit = ARGV.fetch(0).to_i

      3.times { GC.start }
      before = ObjectSpace.memsize_of_all

      require "typhoeus"

      3.times { GC.start }
      retained = ObjectSpace.memsize_of_all - before

      if retained > limit
        warn "require 'typhoeus' retained #{retained} bytes (limit #{limit})"
        exit 1
      end
    RUBY

    lib = File.expand_path("../../lib", __dir__)
    expect(
      system(RbConfig.ruby, "-I", lib, "-e", script, MAX_RETAINED_BYTES.to_s)
    ).to be(true)
  end
end
