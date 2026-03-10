# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "json"
gem "rake"

group :development, :test do
  gem "rspec", "~> 3.0"

  gem "sinatra", "~> 1.3"

  gem "faraday", ">= 0.9", "< 2.0"
  gem "dalli", "~> 2.0"

  gem "webrick"
  gem "logger"
  gem "ostruct"

  gem "redis", "~> 3.0"

  if RUBY_PLATFORM == "java"
    gem "spoon"
  end

  unless ENV["CI"]
    gem "guard-rspec", "~> 0.7"
    gem "rb-fsevent", '~> 0.9.1'
  end
end
