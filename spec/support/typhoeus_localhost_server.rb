require 'net/http'
require 'uri'
require 'rbconfig'

require File.expand_path(File.dirname(__FILE__) + '/spawn')

class TyphoeusLocalhostServer
  class << self
    attr_accessor :pid

    def start_servers!
      self.pid = start_child
      start_parent
      wait_for_servers_to_start
    end

  private

    def start_parent
      # Cleanup.
      at_exit do
        Process.kill('TERM', self.pid) if self.pid
      end
    end

    def start_child
      spawn(RbConfig::CONFIG['ruby_install_name'].sub('ruby', 'rake'), 'start_test_servers')
    end

    def wait_for_servers_to_start
      puts "Waiting for servers to start..."
      ports = [3000, 3001, 3002]

      Timeout::timeout(30) do
        loop do
          up = 0
          ports.each do |port|
            url = "http://localhost:#{port}/"
            begin
              response = Net::HTTP.get_response(URI.parse(url))
              if response.is_a?(Net::HTTPSuccess)
                up += 1
              end
            rescue SystemCallError => error
            end
          end

          if up == ports.size
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
