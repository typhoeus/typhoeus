# frozen_string_literal: true

require 'spec_helper'
require 'rbconfig'

describe "repeated Typhoeus transfers" do
  it "does not accumulate easy handles, responses, or file descriptors" do
    script = <<~'RUBY'
      require "typhoeus"
      require "objspace"

      url = ARGV.fetch(0)

      def snapshot
        Typhoeus::Pool.clear
        3.times { GC.start }

        counts = {
          :easy => ObjectSpace.each_object(Ethon::Easy).count,
          :multi => ObjectSpace.each_object(Ethon::Multi).count,
          :response => ObjectSpace.each_object(Typhoeus::Response).count,
          :file => ObjectSpace.each_object(File).count,
          :pool => Typhoeus::Pool.send(:easies).size
        }
        if defined?(Ethon::Curl::OwnedPointer)
          counts[:native] = Ethon::Curl::OwnedPointer.owners.size
        end
        counts
      end

      def direct_requests(count, url)
        count.times do
          response = Typhoeus.get(url)
          abort "unexpected response: #{response.code}" unless response.code == 200
        end
      end

      def streamed_requests(count, url)
        count.times do
          chunks = 0
          request = Typhoeus::Request.new(url)
          request.on_body { |_chunk, _response| chunks += 1 }
          response = request.run

          abort "unexpected response: #{response.code}" unless response.code == 200
          abort "no streamed chunks" if chunks.zero?
        end
      end

      def hydra_requests(count, url)
        count.times do
          hydra = Typhoeus::Hydra.new(:max_concurrency => 2)
          requests = 2.times.map { Typhoeus::Request.new(url) }
          requests.each { |request| hydra.queue(request) }
          hydra.run

          requests.each do |request|
            code = request.response && request.response.code
            abort "unexpected hydra response: #{code.inspect}" unless code == 200
          end
        end
      end

      direct_requests(3, url)
      streamed_requests(3, url)
      hydra_requests(2, url)
      baseline = snapshot

      direct_requests(15, url)
      streamed_requests(15, url)
      hydra_requests(10, url)
      after = snapshot

      baseline.each do |name, count|
        growth = after.fetch(name) - count
        next if growth <= 2

        abort "#{name} leak: #{count} -> #{after.fetch(name)}"
      end
    RUBY

    lib = File.expand_path("../../lib", __dir__)
    url = defined?(TestServer) ? TestServer.url : "http://localhost:3001"
    expect(system(RbConfig.ruby, "-I", lib, "-e", script, url)).to be(true)
  end
end
