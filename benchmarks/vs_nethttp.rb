require 'rubygems'
require File.dirname(__FILE__) + '/../lib/typhoeus.rb'
require 'open-uri'
require 'benchmark'
include Benchmark


calls = 20
@klass = Class.new do
  include Typhoeus
end

benchmark do |t|    
  t.report("httpmachine") do
    responses = []
    
    calls.times do
      responses << @klass.get("http://127.0.0.1:3000")
    end
    
    responses.each {|r| raise unless r.response_body == "whatever"}
  end

  t.report("net::http") do
    responses = []
    
    calls.times do
      responses << open("http://127.0.0.1:3000").read
    end
    
    responses.each {|r| raise unless r == "whatever"}    
  end
end
