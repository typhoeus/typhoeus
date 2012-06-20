require 'spec_helper'

describe Typhoeus::Request do
  let(:url) { "localhost:3001" }
  let(:options) { {:headers => {'User-Agent' => "Fu"}} }
  let(:request) { Typhoeus::Request.new(url, options) }

  describe ".new" do
    it "stores url" do
      request.url.should eq(url)
    end

    it "stores options" do
      request.options.should eq(options)
    end
  end

  describe "#run" do
    let(:easy) { Ethon::Easy.new }
    before { Typhoeus.expects(:get_easy_object).returns(easy) }

    it "grabs an easy" do
      request.run
    end

    it "generates settings" do
      easy.expects(:http_request)
      request.run
    end

    it "prepares" do
      easy.expects(:prepare)
      request.run
    end

    it "performs" do
      easy.expects(:perform)
      request.run
    end


    it "releases easy" do
      Typhoeus.expects(:release_easy_object)
      request.run
    end

    it "returns a response" do
      request.run.should be_a(Typhoeus::Response)
    end
  end

  describe "#marshal_dump" do
    let(:url) { "http://www.google.com" }

    ['on_complete', 'after_complete'].each do |name|
      context "when #{name} handler" do
        before { request.instance_variable_set("@#{name}", Proc.new{}) }

        it "doesn't include @#{name}" do
          request.send(:marshal_dump).map(&:first).should_not include("@#{name}")
        end

        it "doesn't raise when dumped" do
          expect { Marshal.dump(request) }.to_not raise_error
        end

        context "when loading" do
          let(:loaded) { Marshal.load(Marshal.dump(request)) }

          it "includes url" do
            loaded.url.should eq(request.url)
          end

          it "doesn't include #{name}" do
            loaded.send(name).should be_nil
          end
        end
      end
    end
  end

  [:on_complete, :after_complete].each do |callback|
    describe "##{callback}" do
      it "responds to" do
        request.should respond_to(callback)
      end
    end

    describe "##{callback}=" do
      it "responds to" do
        request.should respond_to("#{callback}=")
      end
    end

    it "executes"
  end

  describe 'cache_key' do
    context "when cache_key_basis" do
      let(:cache_key_basis) { "basis" }
      before { request.cache_key_basis = cache_key_basis }

      it "uses cache_key_basis" do
        Digest::SHA1.expects(:hexdigest).with(cache_key_basis)
        request.cache_key
      end
    end

    context "when no cache key_basis" do
      it "uses url" do
        Digest::SHA1.expects(:hexdigest).with(url)
        request.cache_key
      end
    end
  end

  [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
    describe ".#{name}" do
      let(:response) { Typhoeus::Request.method(name).call(url, options) }

      it "returns ok" do
        response.return_code.should eq(:ok)
      end

      unless name == :head
        it "makes #{name.upcase} requests" do
          response.response_body.should include("\"REQUEST_METHOD\":\"#{name.upcase}\"")
        end
      end
    end
  end
end
