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
# wraps libcurl. Sitting on top of libcurl make Typhoeus
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
  extend Hydra::EasyPool
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
  # @param [ String ] url The url to stub out.
  # @param [ Hash ] options The options to stub out.
  #
  # @return [ Typhoeus::Expectation ] The expecatation.
  #
  # @see Typhoeus::Expectation
  def stub(url, options = {})
    expectation = Expectation.all.find{ |e| e.url == url && e.options == options }
    return expectation if expectation

    Expectation.new(url, options).tap do |new_expectation|
      Expectation.all << new_expectation
    end
  end

  # Add before callbacks.
  #
  # @example Add before callback.
  #   Typhoeus.before { |request| p request.url }
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
