require "spec"
require "spec/rake/spectask"
require 'lib/typhoeus.rb'

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

task :install do
  rm_rf "*.gem"
  puts `gem build typhoeus.gemspec`
  puts `sudo gem install typhoeus-#{Typhoeus::VERSION}.gem`
end