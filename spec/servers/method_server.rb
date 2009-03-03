# this server simply is for testing out the different http methods. it echoes back the passed in info
require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
 
class MethodServer  < EventMachine::Connection
  include EventMachine::HttpServer
 
  def process_http_request
    EventMachine.stop if ENV["PATH_INFO"] == "/die"
    
    resp = EventMachine::DelegatedHttpResponse.new( self )
    
    # Block which fulfills the request
    operation = proc do
      resp.status = 200
      resp.content = request_params + "\n#{@http_post_content}"
    end

    # Callback block to execute once the request is fulfilled
    callback = proc do |res|
      resp.send_response
    end

    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
  
  def request_params
    %w( PATH_INFO QUERY_STRING HTTP_COOKIE IF_NONE_MATCH CONTENT_TYPE REQUEST_METHOD REQUEST_URI ).collect do |param|
      "#{param}=#{ENV[param]}"
    end.join("\n")
  end
end
# 
# port = (ARGV[0] || 3000).to_i
# #Process.fork do
#   EventMachine::run {
#     EventMachine.epoll
#     EventMachine::start_server("0.0.0.0", port, MethodServer)
#   }
# #end