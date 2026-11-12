# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "json"
gem "rake"

group :development, :test do
  gem "rspec", "~> 3.0"
  gem "simplecov", "~> 0.22.0", :require => false

  gem "sinatra", "~> 3.0"
  gem "rack", "~> 2.2"

  gem "faraday", ">= 1.0", "< 3.0"
  gem "dalli", "~> 3.0"

  gem "webrick"
  gem "logger"
  gem "ostruct"

  gem "redis", "~> 5.0"

  if RUBY_PLATFORM == "java"
    gem "spoon"
  end

  unless ENV["CI"]
    gem "guard-rspec", "~> 0.7"
    gem "rb-fsevent", '~> 0.9.1'
  end
end
