# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'typhoeus/version'

Gem::Specification.new do |s|
  s.name         = "typhoeus"
  s.version      = Typhoeus::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["David Balatero", "Paul Dix", "Hans Hasselberg"]
  s.email        = ["hans.hasselberg@gmail.com"]
  s.homepage     = "https://github.com/typhoeus/typhoeus"
  s.summary      = "Parallel HTTP library on top of libcurl multi."
  s.description  = %q{Like a modern code version of the mythical beast with 100 serpent heads, Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling logic.}

  s.required_ruby_version = ">= 2.6"
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri'       => 'https://github.com/typhoeus/typhoeus/issues',
    'changelog_uri'         => "https://github.com/typhoeus/typhoeus/blob/v#{s.version}/CHANGELOG.md",
    'documentation_uri'     => "https://www.rubydoc.info/gems/typhoeus/#{s.version}",
    'rubygems_mfa_required' => 'true',
    'source_code_uri'       => "https://github.com/typhoeus/typhoeus/tree/v#{s.version}"
  }

  s.add_dependency('ethon', [">= 0.19.0", "< 0.20.0"])

  s.files = Dir.chdir(__dir__) do
    files = begin
      IO.popen(["git", "ls-files", "-z"], :err => File::NULL, &:read).split("\x0")
    rescue SystemCallError
      []
    end
    # Building from a source tarball or a container without git must still
    # produce a working gem.
    if files.empty?
      files = Dir["lib/**/*", "*.md", "LICENSE", "typhoeus.gemspec"].
        select { |file| File.file?(file) }
    end
    files.reject do |file|
      file.start_with?(*%w[. Gemfile Guardfile Rakefile perf spec])
    end
  end
  s.require_path = 'lib'
end
