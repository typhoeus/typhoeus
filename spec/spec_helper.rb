# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup

if ENV["COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.root(File.expand_path("..", __dir__))
  SimpleCov.start do
    add_filter "/spec/"
    # Loaded before coverage starts, or only when Rails is present.
    add_filter "lib/typhoeus/railtie.rb"
    add_filter "lib/typhoeus/version.rb"
    track_files "lib/**/*.rb"
    enable_coverage :branch
  end
end

require "typhoeus"
require "rspec"

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.order = :rand

  config.before(:suite) do
    TestServer.port = LocalhostServer.new(TESTSERVER.new).port
  end

  config.after do
    Typhoeus::Pool.clear
    Typhoeus::Expectation.clear
    Typhoeus.before.clear
    Typhoeus.on_complete.clear
    Typhoeus.on_success.clear
    Typhoeus.on_failure.clear
    Typhoeus.on_progress.clear
    Typhoeus.on_headers.clear
    Typhoeus::Config.verbose = false
    Typhoeus::Config.block_connection = false
    Typhoeus::Config.memoize = false
    Typhoeus::Config.max_idle_easies = 20
  end
end
