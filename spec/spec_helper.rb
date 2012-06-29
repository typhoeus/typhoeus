$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

if RUBY_VERSION =~ /1.9/ && RUBY_ENGINE == 'ruby'
  require 'simplecov'

  SimpleCov.start do
    add_filter 'spec'
  end
end

require "bundler"
Bundler.setup
require "typhoeus"
require "rspec"

if RUBY_VERSION =~ /1.9/
  require_relative 'support/boot.rb'
else
  require 'spec/support/boot.rb'
end

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.mock_with(:mocha)

  config.before(:suite) do
    Boot.start_servers
  end
end

