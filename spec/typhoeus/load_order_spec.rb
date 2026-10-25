# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"

describe "optional integrations" do
  it "are available regardless of what was required first" do
    lib = File.expand_path("../../lib", __dir__)
    script = <<~RUBY
      require "typhoeus"

      missing = []
      missing << "Rack::Typhoeus::Middleware::ParamsDecoder" unless defined?(Rack::Typhoeus::Middleware::ParamsDecoder)
      missing << "Typhoeus::Cache::Redis" unless defined?(Typhoeus::Cache::Redis)
      missing << "Typhoeus::Cache::Dalli" unless defined?(Typhoeus::Cache::Dalli)
      missing << "Typhoeus::Cache::Rails" unless defined?(Typhoeus::Cache::Rails)

      abort "missing: \#{missing.join(", ")}" unless missing.empty?
    RUBY

    _, error, status = Open3.capture3(RbConfig.ruby, "-I", lib, "-e", script)

    expect(status).to be_success, error
  end
end
