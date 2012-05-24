require 'net/http'
require 'uri'
require 'rbconfig'

require File.expand_path(File.dirname(__FILE__) + '/spawn')

class TyphoeusLocalhostServer

  PORTS = [3000, 3001, 3002]

  class << self
    attr_accessor :pid

    def start_servers!(mode = :spec)
      if servers_running?
        puts "Servers are up!"
        return
      end

      puts "Starting 3 test servers"
      silence_sinatra = (mode == :spec and RUBY_PLATFORM != 'java' and RbConfig::CONFIG['ruby_host_os'] !~ /mingw|mswin|bccwin/)
      pids = []
      PORTS.each do |port|
        pids << if silence_sinatra
          spawn("exec #{RbConfig::CONFIG['ruby_install_name']} spec/servers/app.rb -p #{port.to_s} >/dev/null 2>&1")
        else
          spawn(RbConfig::CONFIG['ruby_install_name'], "spec/servers/app.rb", "-p", port.to_s)
        end
      end

      at_exit do
        pids.each do |pid|
          puts "Killing pid #{pid}"
          Process.kill("KILL", pid)
        end
      end
      trap('TERM', 'EXIT')

      wait_for_servers_to_start

      # Wait for kill.
      sleep if mode != :spec
    end

    def servers_running?
      up = 0
      PORTS.each do |port|
        url = "http://localhost:#{port}/"
        begin
          response = Net::HTTP.get_response(URI.parse(url))
          if response.is_a?(Net::HTTPSuccess)
            up += 1
          end
        rescue SystemCallError => error
        end
      end
      up == PORTS.size
    end

    def wait_for_servers_to_start
      puts "Waiting for servers to start..."

      Timeout::timeout(30) do
        loop do
          sleep 0.5 # give the forked server processes some time to start

          if servers_running?
            puts "Servers are up!"
            break
          end
        end
      end
    rescue Timeout::Error => error
      abort "Servers never started!"
    end
  end
end
