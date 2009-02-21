$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'curb'

require 'http-machine/remote'

module HTTPMachine
  VERSION = "0.0.1"
  
  def self.service_access
    Thread.current[:curl_multi] ||= Curl::Multi.new
    yield
    Thread.current[:curl_multi].perform
  end
end