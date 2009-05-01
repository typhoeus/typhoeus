$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'cgi'
require 'digest/sha2'
require 'typhoeus/easy'
require 'typhoeus/multi'
require 'typhoeus/native'
require 'typhoeus/filter'
require 'typhoeus/remote_method'
require 'typhoeus/remote'
require 'typhoeus/remote_proxy_object'

module Typhoeus
  VERSION = "0.0.6"
  
  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi] ||= Typhoeus::Multi.new
    Thread.current[:curl_multi].add(easy_object)
  end
  
  def self.perform_easy_requests
    Thread.current[:curl_multi].perform
  end
end