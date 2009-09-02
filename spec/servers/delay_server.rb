# this server simply accepts requests and blocks for a passed in interval before returning a passed in reqeust value to
# the client
require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'yaml'

class DelayFixtureServer  < EventMachine::Connection
  include EventMachine::HttpServer
 
  def process_http_request
    EventMachine.stop if ENV["PATH_INFO"] == "/die"
    puts "#{ENV['PATH_INFO']}?#{ENV['QUERY_STRING']}"
    resp = EventMachine::DelegatedHttpResponse.new( self )
    
    # Block which fulfills the request
    operation = proc do
      sleep get_delay

      resp.status = 200
      resp.content = {:request_method => ENV["REQUEST_METHOD"], :path_info => ENV["PATH_INFO"], :query_string => ENV["QUERY_STRING"]}.to_yaml
    end

    # Callback block to execute once the request is fulfilled
    callback = proc do |res|
      resp.send_response
    end

    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
  
  def get_delay
    ENV["QUERY_STRING"].split("&").each do |pair|
      key, value = pair.split("=")
      return value.to_i if key == "delay"
    end
    return 0
  end
end

port = (ARGV[0] || 3000).to_i

EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", port, DelayFixtureServer)
}
