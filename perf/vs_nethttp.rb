require 'rubygems'
require 'typhoeus'
require 'open-uri'
require 'benchmark'

calls = 1000
url = "http://127.0.0.1:300"
Typhoeus.init_easy_object_pool

Benchmark.bmbm do |bm|
  bm.report("net::http     ") do
    calls.times do |i|
      open(url+"#{i%3}/#{i}")
    end
  end

  bm.report("typhoeus      ") do
    calls.times do |i|
      Typhoeus::Request.get(url+"#{i%3}/#{i}")
    end
  end

  bm.report("typhoeus hydra") do
    calls.times do |i|
      Typhoeus::Hydra.hydra.queue(Typhoeus::Request.new(url+"#{i%3}/#{i}"))
    end
    Typhoeus::Hydra.hydra.run
  end
end
