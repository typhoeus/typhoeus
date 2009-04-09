$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'http-machine/easy'
require 'http-machine/native'
require 'http-machine/remote'

module HTTPMachine
  VERSION = "0.0.1"

  def self.multi_running?
    !Thread.current[:curl_multi].nil?
  end
  
  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi_added] = true
    Thread.current[:curl_multi].add(easy_object)
  end
  
  def self.service_access(&block)
    Thread.current[:curl_multi] ||= Curl::Multi.new
    block.call
    while Thread.current[:curl_multi_added]
      Thread.current[:curl_multi_added] = nil
      Thread.current[:curl_multi].perform
    end
  end
end