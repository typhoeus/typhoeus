require "rubygems"
require "spec"

# gem install redgreen for colored test output
begin require "redgreen" unless ENV['TM_CURRENT_LINE']; rescue LoadError; end

path = File.expand_path(File.dirname(__FILE__) + "/../lib/")
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require "lib/http-machine"

# local servers for running tests
require File.dirname(__FILE__) + "/servers/delay_fixture_server.rb"
require File.dirname(__FILE__) + "/servers/method_server.rb"

def start_method_server(port = 300)
  pid = Process.fork do
    EventMachine::run {
      EventMachine.epoll
      EventMachine::start_server("0.0.0.0", port, MethodServer)
    }
  end
  sleep 0.2
  pid
end

def stop_method_server(pid)
  Process.kill("HUP", pid)
end

# this starts a local server on the specified port. It just takes the request info and echoes it back
def run_method_server(port = 3000)
  pid = Process.fork do
    EventMachine::run {
      EventMachine.epoll
      EventMachine::start_server("0.0.0.0", port, MethodServer)
    }
  end
  begin
    sleep 0.2 # this is a total hack. the server needs a little time to start up before running the test block
    yield
  ensure
    Process.kill("HUP", pid)
  end
end

# this starts a local server on the specified port. The server recieves reqeusts, sleeps for the delay time
# and then returns the contents of the fixture file as the response.
def run_local_server(fixture_file_name, response_delay = 0, port = 3000)
  DelayFixtureServer.response_delay   = response_delay
  DelayFixtureServer.response_fixture = File.read(File.dirname(__FILE__) + "/fixtures/#{fixture_file_name}")
  pid = Process.fork do
    EventMachine::run {
      EventMachine.epoll
      EventMachine::start_server("0.0.0.0", port, DelayFixtureServer)
    }
  end
  begin
    yield
  ensure
    Process.kill("HUP", pid)
  end
end