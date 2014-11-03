require 'typhoeus'

class Cache
  def initialize
    @memory = {}
  end

  def get(request)
    puts request.object_id
    Typhoeus::Response.new
  end

  def set(request, response)
    @memory[request] = response
  end
end

Typhoeus::Config.cache = Cache.new
hydra = Typhoeus::Hydra.new

urls = ["http://web.de"] * 6000

requests = urls.map do |url|
  Typhoeus::Request.new(url).tap do |request|
    request.on_success do |response|
      # callback
    end
  end
end

requests.each {|req| hydra.queue(req)}
hydra.run
