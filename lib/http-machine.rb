$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'cgi'
require 'http-machine/easy'
require 'http-machine/multi'
require 'http-machine/native'
require 'http-machine/remote'

module HTTPMachine
  VERSION = "0.0.1"

  def self.multi_running?
    !Thread.current[:curl_multi_running].nil?
  end
  
  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi].add(easy_object)
  end
  
  def self.service_access(&block)
    Thread.current[:curl_multi] ||= HTTPMachine::Multi.new
    Thread.current[:curl_multi_running] = true
    block.call
    Thread.current[:curl_multi].perform
    Thread.current[:curl_multi_running] = nil
  end
end