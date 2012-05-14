# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'typhoeus/version'
require 'rubygems/package_task'

def Dir.ls_files(*dirs)
  dirs.map do |dir|
    if File.directory?(dir)
      Dir.entries(dir).reject {|file| file[0] == '.' }.map {|file| ls_files(File.join(dir, file)) }
    else dir
    end
  end.flatten
end

Gem::Specification.new do |s|
  s.name         = "typhoeus"
  s.version      = Typhoeus::VERSION
  s.authors      = ["David Balatero", "Paul Dix"]
  s.email        = "dbalatero@gmail.com"
  s.homepage     = "https://github.com/dbalatero/typhoeus"
  s.summary      = "Parallel HTTP library on top of libcurl multi."
  s.description  = %q{Like a modern code version of the mythical beast with 100 serpent heads, Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling logic.}
  s.files        = FileList['ext/**/*',
                     'lib/**/*',
                     'spec/**/*',
                     'CHANGELOG.markdown',
                     'Gemfile',
                     'Gemfile.lock',
                     'LICENSE',
                     'Rakefile',
                     'typhoeus.gemspec']
  s.rubyforge_project = '[none]'

  s.add_runtime_dependency 'ffi', ['>= 0']
  s.add_runtime_dependency 'mime-types', ['>= 0']
  s.add_development_dependency 'diff-lcs', [">= 0"]
  s.add_development_dependency 'sinatra', [">= 0"]
  s.add_development_dependency 'json', [">= 0"]
  s.add_development_dependency 'rake', [">= 0"]
  s.add_development_dependency("mocha", ["~> 0.10"])
  s.add_development_dependency("rspec", ["~> 2.10"])
  s.add_development_dependency("guard-rspec", ["~> 0.6"])
  s.add_development_dependency 'spoon', [">= 0"] if RUBY_PLATFORM == "java"
end
