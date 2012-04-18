$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
end

task :install do
  rm_rf "*.gem"
  puts `gem build typhoeus.gemspec`
  puts `gem install typhoeus-*.gem`
end

desc "Start up the test servers"
task :start_test_servers do
  require 'rbconfig'
  require File.expand_path('../spec/support/spawn', __FILE__)

  puts "Starting 3 test servers"

  pids = []
  [3000, 3001, 3002].each do |port|
    pids << spawn(RbConfig::CONFIG['ruby_install_name'], 'spec/servers/app.rb', '-p', port.to_s)
  end

  at_exit do
    pids.each do |pid|
      puts "Killing pid #{pid}"
      Process.kill("KILL", pid)
    end
  end

  # Wait for kill.
  trap("TERM") { exit } # for jruby to handle kill properly
  sleep
end

desc "Build Typhoeus and run all the tests."
task :default => [:spec]
