require 'typhoeus/requests/callbacks'
require 'typhoeus/requests/actions'
require 'typhoeus/requests/operations'
require 'typhoeus/requests/marshal'
require 'typhoeus/requests/responseable'
require 'typhoeus/requests/memoizable'

module Typhoeus
  class Request
    include Requests::Callbacks
    include Requests::Marshal
    include Requests::Operations
    extend  Requests::Actions
    include Requests::Responseable
    include Requests::Memoizable

    attr_accessor :options, :url, :hydra

    def initialize(url, options = {})
      @url = url
      @options = options.dup

      if @options[:headers]
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(options[:headers])
      else
        @options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end
      @options[:verbose] = Typhoeus::Config.verbose if @options[:verbose].nil?
    end

    def eql?(other)
      self.class == other.class &&
        self.url == other.url &&
        self.options == other.options
    end

    def hash
      [ self.class, self.url, self.options ].hash
    end
  end
end
