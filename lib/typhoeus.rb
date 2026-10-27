# frozen_string_literal: true

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

# Load the optional integrations when their dependency is installed, not when
# the dependency happens to be loaded before Typhoeus. Requiring the adapter
# files is safe because they only reference the dependency at call time.
begin
  require "rack"
  require "rack/typhoeus"
rescue LoadError
  # Rack is optional.
end

require "typhoeus/cache/redis"
require "typhoeus/cache/dalli"
require "typhoeus/cache/rails"

# If we are using Rails, then we will include the Typhoeus railtie.
# if defined?(Rails)
#   require "typhoeus/railtie"
# end

# Typhoeus is a HTTP client library based on Ethon which
# wraps libcurl. Sitting on top of libcurl makes Typhoeus
# very reliable and fast.
#
# There are some gems using Typhoeus like
# {https://github.com/myronmarston/vcr VCR},
# {https://github.com/bblimke/webmock WebMock} or
# {https://github.com/technoweenie/faraday Faraday}. VCR
# and WebMock provide their own adapter whereas
# Faraday relies on {Faraday::Adapter::Typhoeus}
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
  extend Request::Actions
  extend Request::Callbacks::Types

  # The default Typhoeus user agent.
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
  def self.configure
    yield Config
  end

  # Stub out a specific request.
  #
  # @example (see Typhoeus::Expectation)
  #
  # @param [ String ] base_url The url to stub out.
  # @param [ Hash ] options The options to stub out.
  #
  # @return [ Typhoeus::Expectation ] The expecatation.
  #
  # @see Typhoeus::Expectation
  def self.stub(base_url, options = {}, &block)
    expectation = Expectation.all.find{ |e| e.base_url == base_url && e.options == options }
    if expectation.nil?
      expectation = Expectation.new(base_url, options)
      Expectation.all << expectation
    end

    expectation.and_return(&block) unless block.nil?
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
  def self.before(&block)
    @before ||= []
    @before << block if block_given?
    @before
  end

  # Execute given block as if block connection is turned off.
  # The old block connection state is restored afterwards. Stubs are bypassed
  # inside the block, so a stub can forward to the real service without
  # recursing into itself.
  #
  # @example Make a real request, no matter if it's blocked.
  #   Typhoeus::Config.block_connection = true
  #   Typhoeus.get("www.example.com").code
  #   #=> raise Typhoeus::Errors::NoStub
  #
  #   Typhoeus.with_connection do
  #     Typhoeus.get("www.example.com").code
  #     #=> :ok
  #   end
  #
  # @example Let one stubbed URL reach the real service.
  #   Typhoeus.stub("http://elastic:9200") do |request|
  #     Typhoeus.with_connection { request.run }
  #   end
  #
  # @yield Yields control to the block after disabling block_connection for
  #        the current thread. Other threads keep their block_connection
  #        setting.
  # @return [ Object ] Returns the return value of the block.
  #
  # @see Typhoeus::Config.block_connection
  def self.with_connection
    old_block_connection = Thread.current[:typhoeus_block_connection]
    old_stubs_disabled = Thread.current[:typhoeus_stubs_disabled]
    Thread.current[:typhoeus_block_connection] = false
    Thread.current[:typhoeus_stubs_disabled] = true
    yield if block_given?
  ensure
    Thread.current[:typhoeus_block_connection] = old_block_connection
    Thread.current[:typhoeus_stubs_disabled] = old_stubs_disabled
  end

  # Whether connections are blocked for the current thread. The override is
  # thread-local so {with_connection} cannot unblock another thread.
  #
  # @api private
  #
  # @return [ Boolean, nil ] The configured value, or the thread override.
  def self.connection_blocked?
    override = Thread.current[:typhoeus_block_connection]
    override.nil? ? Config.block_connection : override
  end

  # Whether the current thread is inside {with_connection} and therefore
  # bypasses stubs.
  #
  # @api private
  #
  # @return [ Boolean ] True when stubs should be skipped.
  def self.stubs_disabled?
    Thread.current[:typhoeus_stubs_disabled]
  end
end
