require "rubygems"
require 'json'
require "rspec"

# gem install redgreen for colored test output
begin require "redgreen" unless ENV['TM_CURRENT_LINE']; rescue LoadError; end

path = File.expand_path(File.dirname(__FILE__) + "/../lib/")
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require path + '/typhoeus'

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    TyphoeusLocalhostServer.start_servers!
  end
end
