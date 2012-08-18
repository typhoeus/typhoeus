require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/errors'
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
  extend Hydra::EasyPool
  extend Request::Actions
  extend Request::Callbacks::Types

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

  # Stub out specific request.
  #
  # @example Stub.
  #   Typhoeus.stub("www.example.com").and_return(Typhoeus::Response.new)
  #
  # @param [ String ] url The url to stub out.
  # @param [ Hash ] options The options to stub out.
  #
  # @return [ Expection ] The expection.
  def stub(url, options = {})
    expectation = Expectation.all.find{ |e| e.url == url && e.options == options }
    return expectation if expectation

    Expectation.new(url, options).tap do |new_expectation|
      Expectation.all << new_expectation
    end
  end

  # Execute given block as if block connection is turned off.
  # The old block connection state is restored afterwards.
  #
  # @param [ Block ] block The block to execute.
  def with_connection
    old = Config.block_connection
    Config.block_connection = false
    yield if block_given?
    Config.block_connection = old
  end
end
