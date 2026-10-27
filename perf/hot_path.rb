# frozen_string_literal: true

# Benchmarks the request hot path: building a request, queueing it, adding it
# to a hydra, and performing it. Run with `bundle exec ruby perf/hot_path.rb`
# or `bundle exec rake perf`.
#
# The micro benchmarks use a stub so libcurl and the test server do not
# dominate the numbers. The last benchmarks perform real requests against a
# local server to include the complete path.

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "typhoeus"
require_relative "benchmark"
require_relative "../spec/support/localhost_server"
require_relative "../spec/support/server"

server = LocalhostServer.new(TESTSERVER.new)
url = "http://127.0.0.1:#{server.port}/"

puts "Ruby: #{RUBY_DESCRIPTION}"
puts "Typhoeus: #{Typhoeus::VERSION}"
puts "URL: #{url}"

results = []

results << Perf.measure("Request.new", 100_000) do
  Typhoeus::Request.new(url)
end

hydra = Typhoeus::Hydra.new
results << Perf.measure("Hydra#queue", 100_000) do
  hydra.queue(Typhoeus::Request.new(url))
  hydra.abort
end

Typhoeus.stub(url) { Typhoeus::Response.new(:code => 200) }
hydra = Typhoeus::Hydra.new
results << Perf.measure("Hydra#add (stubbed)", 50_000) do
  hydra.add(Typhoeus::Request.new(url))
end

Typhoeus.before { true }
results << Perf.measure("Hydra#add (before hook)", 50_000) do
  hydra.add(Typhoeus::Request.new(url))
end

if Typhoeus::Config.respond_to?(:exclude_features)
  Typhoeus::Config.exclude_features = [:before]
  results << Perf.measure("Hydra#add (before excluded)", 50_000) do
    hydra.add(Typhoeus::Request.new(url))
  end
  Typhoeus::Config.exclude_features = nil
end

Typhoeus.before.clear
Typhoeus::Expectation.clear

results << Perf.measure("Request.get", 500) do
  response = Typhoeus.get(url)
  raise "unexpected response: #{response.code}" unless response.code == 200
end

hydra = Typhoeus::Hydra.new
results << Perf.measure("Hydra run (1 request)", 500) do
  hydra.queue(Typhoeus::Request.new(url))
  hydra.run
end

results << Perf.measure("Hydra run (10 requests)", 100) do
  10.times { hydra.queue(Typhoeus::Request.new(url)) }
  hydra.run
end

Perf.report(results)
