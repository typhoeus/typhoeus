# frozen_string_literal: true

module Typhoeus

  # The Typhoeus configuration used to set global
  # options.
  # @example Set the configuration options within a block.
  #   Typhoeus.configure do |config|
  #     config.verbose = true
  #   end
  #
  # @example Set the configuration directly.
  #   Typhoeus::Config.verbose = true
  module Config
    extend self

    # Defines whether the connection is blocked.
    # Defaults to false. When set to true, only
    # stubbed requests are allowed. A
    # {Typhoeus::Errors::NoStub} error is raised,
    # when trying to do a real request. It's possible
    # to work around inside
    # {Typhoeus.with_connection}.
    #
    # @return [ Boolean ]
    #
    # @see Typhoeus::Request::BlockConnection
    # @see Typhoeus::Hydra
    # @see Typhoeus#with_connection
    # @see Typhoeus::Errors::NoStub
    attr_accessor :block_connection

    # Defines whether GET requests are memoized when using the {Typhoeus::Hydra}.
    #
    # @return [ Boolean ]
    #
    # @see Typhoeus::Hydra
    # @see Typhoeus::Request::Memoizable
    attr_accessor :memoize

    # Defines whether curls debug output is shown.
    # With Ethon 0.19 the output is written through Ethon.logger at the
    # debug level; older versions print it to stderr.
    #
    # @return [ Boolean ]
    #
    # @see http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTVERBOSE
    attr_accessor :verbose

    # Defines the default HTTP timeout for the entire request in seconds
    # See README for more details about timeouts
    #
    # @return [ Integer, Float ]
    #
    # @see https://curl.haxx.se/libcurl/c/curl_easy_setopt#CURLOPTTIMEOUT
    attr_accessor :timeout

    # Defines the default HTTP timeout for the connection phase in seconds
    # See README for more details about timeouts
    #
    # @return [ Integer, Float ]
    #
    # @see https://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCONNECTTIMEOUT
    attr_accessor :connecttimeout

    # Defines whether requests are cached.
    #
    # @return [ Object ]
    #
    # @see Typhoeus::Hydra
    # @see Typhoeus::Request::Cacheable
    attr_accessor :cache

    # Defines optional hydra features that should be skipped. Currently
    # `:before` is supported. Skipping {Typhoeus.before} saves a callback
    # lookup and invocation for every request that is added to a hydra.
    #
    # @example Skip before callbacks.
    #   Typhoeus::Config.exclude_features = [:before]
    #
    # @return [ Array<Symbol>, nil ]
    #
    # @see Typhoeus::Hydra#add
    attr_accessor :exclude_features

    # Defines whether to use a default user agent.
    #
    # @return [ String ]
    #
    # @see Typhoeus::Request#set_defaults
    attr_accessor :user_agent

    # Defines wether to use a proxy server for every request.
    #
    # @return [ String ]
    #
    # @see Typhoeus::Request#set_defaults
    attr_accessor :proxy

    # Defines the maximum number of idle easy handles kept in the
    # process-wide pool. Defaults to 20. Set it to nil to keep every
    # handle, or to 0 to disable pooling.
    #
    # @return [ Integer, nil ]
    #
    # @see Typhoeus::Pool
    attr_reader :max_idle_easies

    def max_idle_easies=(value)
      if !value.nil? && (!value.is_a?(Integer) || value < 0)
        raise ArgumentError, "max_idle_easies must be nil or a non-negative Integer"
      end

      @max_idle_easies = value
    end

    @max_idle_easies = 20
  end
end
