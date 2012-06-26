require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/hydra'
require 'typhoeus/version'

module Typhoeus
  extend self
  extend Hydras::EasyPool
  extend Requests::Actions
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  def configure
    yield Config
  end
end
