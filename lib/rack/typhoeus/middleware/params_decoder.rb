# frozen_string_literal: true

require 'rack/typhoeus/middleware/params_decoder/helper'

module Rack
  module Typhoeus
    module Middleware

      # This Rack middleware takes care of the proper deserialization of
      # the nested params encoded by Typhoeus.
      #
      # @example Require the railtie when using Rails.
      #   require 'typhoeus/railtie'
      #
      # @example Include the middleware for Rack based applications.
      #   use Rack::Typhoeus::Middleware::ParamsDecoder
      #
      # @example Use the helper directly. Not recommended as b/c the interface might change.
      #   require 'rack/typhoeus/middleware/params_decoder/helper'
      #   include Rack::Typhoeus::Middleware::ParamsDecoder::Helper
      #   decode!(params)
      #
      # @author Dwayne Macgowan
      # @since 0.5.4
      class ParamsDecoder
        include ParamsDecoder::Helper

        def initialize(app)
          @app = app
        end

        def call(env)
          req = Rack::Request.new(env)

          # Query and form parameters are separate sources. Decoding the
          # merged Rack::Request#params and writing the result to both would
          # let a form value overwrite the query value for the same key.
          decode(req.GET).each_pair { |k, v| req.GET[k] = v }
          decode(req.POST).each_pair { |k, v| req.POST[k] = v }

          @app.call(env)
        end
      end
    end
  end
end
