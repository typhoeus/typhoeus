require 'typhoeus/requests/callbacks'
require 'typhoeus/requests/actions'
require 'typhoeus/requests/operations'
require 'typhoeus/requests/marshal'
require 'typhoeus/requests/cache_key'

module Typhoeus
  class Request
    include Requests::Callbacks
    include Requests::Marshal
    include Requests::Operations
    include Requests::Actions
    include Requests::CacheKey

    attr_accessor :response, :options, :url

    def initialize(url, options = {})
      @url = url
      @options = options.dup

      if @options[:headers]
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(options[:headers])
      else
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end
    end

    def action
      @options[:method]
    end
  end
end
