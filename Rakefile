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
  require 'spec/support/typhoeus_localhost_server'
  begin
    TyphoeusLocalhostServer.start_servers!(:rake)
    sleep
  rescue Exception
  end
end

desc "Build Typhoeus and run all the tests."
task :default => [:build_native, :spec]
