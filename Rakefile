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
  system("cd ext/typhoeus && make clean && ruby extconf.rb && make")
end

desc "Start up the test servers"
task :start_test_servers do
  puts "Starting 3 test servers"
  (3000..3002).map do |port|
    Thread.new do
      system("ruby spec/servers/app.rb -p #{port}")
    end
  end.each(&:join)
end

desc "Build Typhoeus and run all the tests."
task :default => [:build_native, :spec]
