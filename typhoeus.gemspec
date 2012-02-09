# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'typhoeus/version'

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
  s.extensions   = ["ext/typhoeus/extconf.rb"]
  s.files        = Dir.ls_files(
                     'ext',
                     'lib',
                     'spec',
                     'CHANGELOG.markdown',
                     'Gemfile',
                     'Gemfile.lock',
                     'LICENSE',
                     'Rakefile',
                     'typhoeus.gemspec'
                   )
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_runtime_dependency 'mime-types', ['>= 0']
  s.add_development_dependency 'rspec', ["~> 2.6"]
  s.add_development_dependency 'diff-lcs', [">= 0"]
  s.add_development_dependency 'sinatra', [">= 0"]
  s.add_development_dependency 'json', [">= 0"]
  s.add_development_dependency 'rake', [">= 0"]
end
