source 'https://rubygems.org'
gemspec

if Gem.ruby_version < Gem::Version.new('2.0.0')
  gem 'json', '< 2'
  gem 'rake', '< 11'
else
  gem 'json'
  gem 'rake'
end

group :development, :test do
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 1.28.0'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'

  gem 'sinatra', '~> 1.3'

  if Gem.ruby_version >= Gem::Version.new('1.9.0')
    gem 'dalli', '~> 2.0'
    gem 'faraday', '>= 0.9', '< 2.0'
  end

  gem 'webrick' if Gem.ruby_version >= Gem::Version.new('3.0.0')

  gem 'redis', '~> 3.0'

  gem 'spoon' if RUBY_PLATFORM == 'java'

  unless ENV['CI']
    gem 'guard-rspec', '~> 0.7'
    gem 'rb-fsevent', '~> 0.9.1'
  end
end
