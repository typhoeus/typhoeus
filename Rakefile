$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
end

task :install do
  rm_rf "*.gem"
  puts `gem build typhoeus.gemspec`
  puts `gem install typhoeus-#{Typhoeus::VERSION}.gem`
end

desc "Builds the native code"
task :build_native do
  system("cd ext/typhoeus && ruby extconf.rb && make clean && make")
end

desc "Start up the test servers"
task :start_test_servers do
  puts "Starting 3 test servers"

  pids = []
  [3000, 3001, 3002].each do |port|
    if pid = fork
      pids << pid
    else
      exec('ruby', 'spec/servers/app.rb', '-p', port.to_s)
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

desc "Build Typhoeus and run all the tests."
task :default => [:build_native, :spec]
