$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup
require "typhoeus"
require "rspec"

if defined? require_relative
  require_relative 'support/localhost_server.rb'
  require_relative 'support/server.rb'
else
  require 'support/localhost_server.rb'
  require 'support/server.rb'
end

RSpec.configure do |config|
  config.order = :rand

  config.before(:suite) do
    LocalhostServer.new(TESTSERVER.new, 3001)
  end
end
