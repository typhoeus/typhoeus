require 'rubygems'
require File.dirname(__FILE__) + '/../lib/http-machine.rb'
require 'open-uri'
require 'benchmark'
include Benchmark

require 'sax-machine'

iterations = 1
calls = 20

class Result
  include SAXMachine
  element :id
  element :name
  element :description
end

class ResultSet
  include HTTPMachine
  remote_server "http://127.0.0.1:3001"
  remote_method :get,  {
    :resource => "",
    :method => :get, 
    :response_handler => :parse }

  include SAXMachine
  element :ttl
  elements :result, :as => :results, :class => Result
end

benchmark do |t|    
  t.report("httpmachine") do
    iterations.times do
      HTTPMachine.service_access do      
        calls.times do
          ResultSet.get({:http_machine => {:server => "http://127.0.0.1:3000"}}) do |result_set|
            # nothing
          end
        end
      end
    end
  end

  t.report("net::http") do
    iterations.times do
      calls.times do
        ResultSet.parse(open("http://127.0.0.1:3000"))
      end
    end
  end
end
