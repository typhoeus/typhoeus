require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/easy_factory'
require 'typhoeus/errors'
require 'typhoeus/expectation'
require 'typhoeus/hydra'
require 'typhoeus/pool'
require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/version'

# If we are using any Rack based application then we need the Typhoeus rack
# # middleware to ensure our app is running properly.
if defined?(Rack)
  require "rack/typhoeus"
end

# If we are using Rails then we will include the Typhoeus railtie.
# if defined?(Rails)
#   require "typhoeus/railtie"
# end

# Typhoeus is a http client library based on Ethon which
# wraps libcurl. Sitting on top of libcurl makes Typhoeus
# very reliable and fast.
#
# There are some gems using Typhoeus like
# {https://github.com/myronmarston/vcr VCR},
# {https://github.com/bblimke/webmock Webmock} or
# {https://github.com/technoweenie/faraday Faraday}. VCR
# and Webmock are providing their own adapter
# whereas Faraday relies on {Faraday::Adapter::Typhoeus}
# since Typhoeus version 0.5.
#
# @example (see Typhoeus::Request)
# @example (see Typhoeus::Hydra)
#
# @see Typhoeus::Request
# @see Typhoeus::Hydra
# @see Faraday::Adapter::Typhoeus
#
# @since 0.5.0
module Typhoeus
  extend self
  extend Request::Actions
  extend Request::Callbacks::Types

  # The default typhoeus user agent.
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  # Set the Typhoeus configuration options by passing a block.
  #
  # @example (see Typhoeus::Config)
  #
  # @yield [ Typhoeus::Config ]
  #
  # @return [ Typhoeus::Config ] The configuration.
  #
  # @see Typhoeus::Config
  def configure
    yield Config
  end

  # Stub out specific request.
  #
  # @example (see Typhoeus::Expectation)
  #
  # @param [ String ] base_url The url to stub out.
  # @param [ Hash ] options The options to stub out.
  #
  # @return [ Typhoeus::Expectation ] The expecatation.
  #
  # @see Typhoeus::Expectation
  def stub(base_url, options = {}, &block)
    expectation = Expectation.all.find{ |e| e.base_url == base_url && e.options == options }
    if expectation.nil?
      expectation = Expectation.new(base_url, options)
      Expectation.all << expectation
    end

    expectation.and_return &block unless block.nil?
    expectation
  end

  # Add before callbacks.
  #
  # @example Add before callback.
  #   Typhoeus.before { |request| p request.base_url }
  #
  # @param [ Block ] block The callback.
  #
  # @yield [ Typhoeus::Request ]
  #
  # @return [ Array<Block> ] All before blocks.
  def before(&block)
    @before ||= []
    @before << block if block_given?
    @before
  end

  # Execute given block as if block connection is turned off.
  # The old block connection state is restored afterwards.
  #
  # @example Make a real request, no matter if its blocked.
  #   Typhoeus::Config.block_connection = true
  #   Typhoeus.get("www.example.com").code
  #   #=> raise Typhoeus::Errors::NoStub
  #
  #   Typhoeus.with_connection do
  #     Typhoeus.get("www.example.com").code
  #     #=> :ok
  #   end
  #
  # @param [ Block ] block The block to execute.
  #
  # @return [ Object ] Returns the return value of block.
  #
  # @see Typhoeus::Config#block_connection
  def with_connection
    old = Config.block_connection
    Config.block_connection = false
    result = yield if block_given?
    Config.block_connection = old
    result
  end
end
