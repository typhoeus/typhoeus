require 'rubygems'
require File.dirname(__FILE__) + '/../lib/http-machine.rb'
require 'open-uri'
require 'benchmark'
include Benchmark

require 'sax-machine'

# class Result
#   include SAXMachine
#   element :id
#   element :name
#   element :description
# end
# 
# class ResultSet
#   include HTTPMachine
#   remote_server "http://127.0.0.1:3001"
#   remote_method :get,  {
#     :resource => "",
#     :method => :get, 
#     :response_handler => :parse }
# 
#   include SAXMachine
#   element :ttl
#   elements :result, :as => :results, :class => Result
# end

calls = 10
@klass = Class.new do
  include HTTPMachine
end
benchmark do |t|    
  t.report("httpmachine") do
    HTTPMachine.service_access do      
      calls.times do
        s = nil
        @klass.get("http://127.0.0.1:3000") do |response_code, response_body|
          s = response_body
        end
      end
    end
  end

  t.report("net::http") do
    calls.times do
      s = open("http://127.0.0.1:3000").read
    end
  end
end
