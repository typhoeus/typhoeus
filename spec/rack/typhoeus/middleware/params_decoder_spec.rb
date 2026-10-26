# frozen_string_literal: true

require 'spec_helper'
require 'rack/mock'

describe "Rack::Typhoeus::Middleware::ParamsDecoder" do
  let(:klass) { Rack::Typhoeus::Middleware::ParamsDecoder }
  let(:app) { lambda { |env| [200, {}, ["ok"]] } }
  let(:middleware) { klass.new(app) }

  def call(path, options = {})
    env = Rack::MockRequest.env_for(path, options)
    middleware.call(env)
    Rack::Request.new(env)
  end

  describe "#call" do
    it "decodes array params in the query string" do
      request = call("/?x[0]=a&x[1]=b")

      expect(request.GET["x"]).to eq(["a", "b"])
    end

    it "decodes nested array params in the query string" do
      request = call("/?x[0][y]=a&x[0][z]=b")

      expect(request.GET["x"]).to eq([{ "y" => "a", "z" => "b" }])
    end

    it "leaves non-array params intact" do
      request = call("/?x=a")

      expect(request.GET["x"]).to eq("a")
    end

    it "decodes array params in the request body" do
      request = call(
        "/",
        :method => "POST",
        :input => "x[0]=a&x[1]=b",
        "CONTENT_TYPE" => "application/x-www-form-urlencoded"
      )

      expect(request.POST["x"]).to eq(["a", "b"])
    end

    it "keeps query and form values separate when both contain a key" do
      request = call(
        "/?x[0]=query",
        :method => "POST",
        :input => "x[0]=form",
        "CONTENT_TYPE" => "application/x-www-form-urlencoded"
      )

      expect(request.GET["x"]).to eq(["query"])
      expect(request.POST["x"]).to eq(["form"])
      expect(request.params["x"]).to eq(["form"])
    end

    it "passes the environment to the app" do
      env = Rack::MockRequest.env_for("/")
      seen = nil
      middleware = klass.new(lambda { |app_env| seen = app_env; [200, {}, ["ok"]] })

      middleware.call(env)

      expect(seen).to be(env)
    end
  end

  describe "#decode_typhoeus_arrays" do
    let(:controller) do
      Class.new do
        include Rack::Typhoeus::Middleware::ParamsDecoder::Helper

        def params
          @params ||= { "x" => { "0" => "a", "1" => "b" } }
        end
      end.new
    end

    it "decodes the params in place" do
      controller.decode_typhoeus_arrays

      expect(controller.params["x"]).to eq(["a", "b"])
    end
  end

  context "when requesting" do
    let(:response) { Typhoeus.get(TestServer.host, :params => {:x => [:a]}) }

    it "transforms parameters" do
      expect(response.body).to include("query_hash\":{\"x\":[\"a\"]}")
    end
  end
end
