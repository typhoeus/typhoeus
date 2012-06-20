module Typhoeus
  class Request
    def initialize(url, options = {})
      @url = url
      @options = options.dup

      if options[:headers]
        options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}.merge(options[:headers])
      else
        options[:headers] = {'User-Agent' => Typhoeus::USER_AGENT}
      end
    end

    def url
      @url
    end

    def options
      @options
    end

    def action
      @options[:method]
    end

    def response
      @response
    end

    def response=(value)
      @response = value
    end

    def on_complete(&block)
      @on_complete = block
    end

    def on_complete=(proc)
      @on_complete = proc
    end

    def after_complete(&block)
      @after_complete = block
    end

    def after_complete=(proc)
      @after_complete = proc
    end

    def cache_key_basis=(value)
      @cache_key_basis = value
    end

    def cache_key_basis
      @cache_key_basis
    end

    def cache_key
      Digest::SHA1.hexdigest(cache_key_basis || url)
    end

    def self.run(url, params = {})
      r = new(url, params)
      r.easy.prepare
      r.easy.perform
      @response = Response.new(r.easy.to_hash)
      Typhoeus.release_easy_object(r.easy)
      @response
    end

    def easy
      return @easy if @easy
      @easy = Typhoeus.get_easy_object
      @easy.http_request(url, options[:method], options)
      @easy
    end

    def run
      easy.prepare
      easy.perform
      Response.new(easy.to_hash)
    end

    module ClassMethods
      [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
        define_method(name) do |url, params|
          run(url, params.merge(:method => name))
        end
      end
    end
    extend ClassMethods

  protected

    # Return the important data needed to serialize this Request, except the
    # `on_complete` and `after_complete` handlers, since they cannot be
    # marshalled.
    def marshal_dump
      (instance_variables - ['@on_complete', '@after_complete', :@on_complete, :@after_complete]).map do |name|
        [name, instance_variable_get(name)]
      end
    end

    def marshal_load(attributes)
      attributes.each { |name, value| instance_variable_set(name, value) }
    end
  end
end
