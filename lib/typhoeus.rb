$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'cgi'
require 'digest/sha2'
require 'typhoeus/easy'
require 'typhoeus/multi'
require 'typhoeus/native'
require 'typhoeus/filter'
require 'typhoeus/remote_method'
require 'typhoeus/remote'

module Typhoeus
  VERSION = "0.0.5"
  
  def self.add_after_service_access_callback(&block)
    @after_service_access_callbacks ||= []
    @after_service_access_callbacks << block
  end

  def self.multi_running?
    !Thread.current[:curl_multi_running].nil?
  end
  
  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi].add(easy_object)
  end
  
  def self.service_access(&block)
    Thread.current[:curl_multi] ||= Typhoeus::Multi.new
    Thread.current[:curl_multi_running] = true
    block.call
    Thread.current[:curl_multi].perform
    Thread.current[:curl_multi_running] = nil
    @after_service_access_callbacks.each {|b| b.call} unless @after_service_access_callbacks.nil?
  end
end