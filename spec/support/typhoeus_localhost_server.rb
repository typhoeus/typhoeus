require 'net/http'
require 'uri'

class TyphoeusLocalhostServer

  PORTS = [3000, 3001, 3002]

  class << self
    attr_accessor :pid

    def start_servers!(mode = :spec)
      return if servers_running?

      if self.pid = fork
        start_parent if mode == :spec
        wait_for_servers_to_start
      else
        start_children(mode)
      end
    end

  private

    def start_parent
      # Cleanup.
      at_exit do
        Process.kill('QUIT', self.pid) if self.pid
      end
    end

    def start_children(mode)
      puts "Starting 3 test servers"
      silence_sinatra = mode == :spec
      pids = []
      PORTS.each do |port|
        if pid = fork
          pids << pid
        elsif silence_sinatra
          exec("exec ruby spec/servers/app.rb -p #{port.to_s} >/dev/null 2>&1")
        else
          exec("ruby", "spec/servers/app.rb", "-p", port.to_s)
        end
      end

      at_exit do
        pids.each do |pid|
          puts "Killing pid #{pid}"
          Process.kill("KILL", pid)
        end
      end

      # Wait for kill.
      sleep
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

      Timeout::timeout(10) do
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
