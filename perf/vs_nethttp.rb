require 'rubygems'
require File.dirname(__FILE__) + '/../lib/typhoeus.rb'
require 'open-uri'
require 'benchmark'

calls = 5000
url = "http://127.0.0.1:3000/"
Typhoeus.init_easy_object_pool

Benchmark.bmbm do |bm|
  bm.report("net::http") do
    calls.times do |i|
      open(url+i.to_s)
    end
  end

  bm.report("typhoeus ") do
    calls.times do |i|
      Typhoeus::Request.get(url+i.to_s)
    end
  end
end
