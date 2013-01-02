$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup
require "typhoeus"
require "rspec"

if RUBY_VERSION =~ /^(1.9|2.0)/
  require_relative 'support/boot.rb'
else
  require 'spec/support/boot.rb'
end

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    Boot.start_servers
  end
end

