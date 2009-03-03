# this server simply accepts requests and blocks for a passed in interval before returning a passed in reqeust value to
# the client
require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
 
class DelayFixtureServer  < EventMachine::Connection
  include EventMachine::HttpServer
 
  def process_http_request
    EventMachine.stop if ENV["PATH_INFO"] == "/die"
    
    resp = EventMachine::DelegatedHttpResponse.new( self )
    
    # Block which fulfills the request
    operation = proc do
      sleep DelayFixtureServer.response_delay

      resp.status = 200
      resp.content = DelayFixtureServer.response_fixture
    end

    # Callback block to execute once the request is fulfilled
    callback = proc do |res|
      resp.send_response
    end

    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
  
  def self.response_fixture
    @response_fixture ||= ""
  end
  
  def self.response_fixture=(val)
    @response_fixture = val
  end

  def self.response_delay
    @response_delay ||= 0
  end

  def self.response_delay=(val)
    @response_delay = val
  end
end

# port = (ARGV[0] || 3000).to_i
# 
# DelayFixtureServer.response_delay   = (ARGV[1].to_f || 0.1)
# DelayFixtureServer.response_fixture = ARGV[2].nil? ? nil : File.read(File.dirname(__FILE__) + "/../fixtures/#{ARGV[2]}")
# 
# Process.fork do
#   EventMachine::run {
#     EventMachine.epoll
#     EventMachine::start_server("0.0.0.0", port, DelayFixtureServer)
#   }
# end