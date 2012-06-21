require 'typhoeus'
require 'net/http'
require 'open-uri'
require 'benchmark'

URL = "http://localhost:300"
Typhoeus.init_easy_object_pool
Typhoeus::Hydra.hydra = Typhoeus::Hydra.new(max_concurrency: 3)

def url_for(i)
  "#{URL}#{i%3}/#{i}"
end

Benchmark.bm do |bm|

  [1000].each do |calls|
    puts "[ #{calls} requests ]"

    bm.report("net/http     ") do
      calls.times do |i|
        uri = URI.parse(url_for(i))
        Net::HTTP.get_response(uri)
      end
    end

    bm.report("open         ") do
      calls.times do |i|
        open(url_for(i))
      end
    end

    bm.report("request      ") do
      calls.times do |i|
        Typhoeus::Request.get(url_for(i), {})
      end
    end

    bm.report("hydra        ") do
      calls.times do |i|
        Typhoeus::Hydra.hydra.queue(Typhoeus::Request.new(url_for(i)))
      end
      Typhoeus::Hydra.hydra.run
    end
  end

  [3].each do |calls|
    puts "[ #{calls} delayed requests ]"

    bm.report("delayed hydra") do
      calls.times do |i|
        Typhoeus::Hydra.hydra.queue(Typhoeus::Request.new("localhost:3001/i?delay=1"))
      end
      Typhoeus::Hydra.hydra.run
    end
  end
end
