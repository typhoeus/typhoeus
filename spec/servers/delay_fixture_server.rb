# this server simply accepts requests and blocks for a passed in interval before returning a passed in reqeust value to
# the client
require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
 
class Handler  < EventMachine::Connection
  include EventMachine::HttpServer
 
  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )
 
    # Block which fulfills the request
    operation = proc do
      sleep 0.1 # simulate a long running request
 
      resp.status = 200
      resp.content = <<-XML
        <result_set>
          <ttl>20</ttl>
          <result>
            <id>1</id>
            <name>hello</name>
            <description>
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
            </description>
          </result>
          <result>
            <id>2</id>
            <name>hello</name>
            <description>
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
            </description>
          </result>
          <result>
            <id>3</id>
            <name>hello</name>
            <description>
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
              this is a long description for a text field of some kind.
            </description>
          </result>
        </result_set>
      XML
    end
 
    # Callback block to execute once the request is fulfilled
    callback = proc do |res|
      resp.send_response
    end
 
    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
end
 
EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", ARGV[0].to_i, Handler)
  puts "Listening..."
}
