require 'digest/sha2'
require 'ethon'

require 'typhoeus/response'
require 'typhoeus/request'
require 'typhoeus/hydra'
require 'typhoeus/hydra_mock'
require 'typhoeus/version'

module Typhoeus
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  def self.easy_object_pool
    @easy_objects ||= []
  end

  def self.init_easy_object_pool
    20.times do
      easy_object_pool << Ethon::Easy.new
    end
  end

  def self.release_easy_object(easy)
    easy.reset
    easy_object_pool << easy
  end

  def self.get_easy_object
    easy_object_pool.pop || Ethon::Easy.new
  end

  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi] ||= Ethon::Multi.new
    Thread.current[:curl_multi].add(easy_object)
  end

  def self.perform_easy_requests
    multi = Thread.current[:curl_multi]
    start_time = Time.now
    multi.easy_handles.each do |easy|
      easy.start_time = start_time
    end
    multi.perform
  end
end
