require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/hydra'
require 'typhoeus/version'

module Typhoeus
  extend self
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  def easy_object_pool
    @easy_objects ||= []
  end

  def init_easy_object_pool
    20.times do
      easy_object_pool << Ethon::Easy.new
    end
  end

  def release_easy_object(easy)
    easy.reset
    easy_object_pool << easy
  end

  def get_easy_object
    easy_object_pool.pop || Ethon::Easy.new
  end

  def add_easy_request(easy_object)
    Thread.current[:curl_multi] ||= Ethon::Multi.new
    Thread.current[:curl_multi].add(easy_object)
  end

  def perform_easy_requests
    multi = Thread.current[:curl_multi]
    start_time = Time.now
    multi.easy_handles.each do |easy|
      easy.start_time = start_time
    end
    multi.perform
  end

  def configure
    yield Config
  end
end
