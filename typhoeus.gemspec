# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'typhoeus/version'

Gem::Specification.new do |s|
  s.name         = "typhoeus"
  s.version      = Typhoeus::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["David Balatero", "Paul Dix", "Hans Hasselberg"]
  s.email        = "hans.hasselberg@gmail.com"
  s.homepage     = "https://github.com/dbalatero/typhoeus"
  s.summary      = "Parallel HTTP library on top of libcurl multi."
  s.description  = %q{Like a modern code version of the mythical beast with 100 serpent heads, Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling logic.}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = '[none]'

  s.add_dependency('ffi', ['~> 1.0'])
  s.add_dependency('mime-types', ['~> 1.18'])
  s.add_dependency('activesupport', ['~> 3.2'])

  s.add_development_dependency('sinatra', ['~> 1.3'])
  s.add_development_dependency('json', ['~> 1.7'])
  s.add_development_dependency('rake', ['~> 0.9'])
  s.add_development_dependency("mocha", ["~> 0.10"])
  s.add_development_dependency("rspec", ["~> 2.10"])
  s.add_development_dependency("guard-rspec", ["~> 0.6"])
  s.add_development_dependency('spoon') if RUBY_PLATFORM == "java"

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md Gemfile LICENSE README.md Rakefile)
  s.require_path = lib
end
