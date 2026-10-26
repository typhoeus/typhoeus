# frozen_string_literal: true

require "typhoeus"

module Rails
  module Typhoeus
    class Railtie < Rails::Railtie
      # Need to include the Typhoeus middleware.
      initializer "typhoeus.params_decoder" do |app|
        app.config.middleware.use Rack::Typhoeus::Middleware::ParamsDecoder
      end
    end
  end
end
