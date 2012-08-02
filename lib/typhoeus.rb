require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/expectation'
require 'typhoeus/hydra'
require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/version'

# Typhoeus is a http client library based on Ethon which
# wraps libcurl.
#
# If you want to make a single request, go with:
#   Typhoeus.get("www.example.com")
#
# When you looking for firing a bunch of requests automatically
# choose the hydra:
#
#   hydra = Typhoeus::Hydra.new
#   requests = (0..9).map{ Typhoeus::Request.new("www.example.com") }
#   requests.each{ |request| hydra.queue(request) }
#   hydra.run
module Typhoeus
  extend self
  extend Hydras::EasyPool
  extend Requests::Actions

  # The default typhoeus user agent.
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  # Set the Typhoeus configuration options by passing a block.
  #
  # @example Set the configuration options.
  #   Typhoeus.configure do |config|
  #     config.verbose = true
  #   end
  #
  # @return [ Config ] The configuration object.
  def configure
    yield Config
  end

  def stub(url, options = {})
    Expectation.new(url, options).tap do |expectation|
      expectations << expectation
    end
  end

  def expectations
    @expectations ||= []
  end
end
