require 'typhoeus'

class Requests
  attr_accessor :requests

  def initialize
    @requests = []
  end

  # add navbar to the request bundle
  def add request
    @requests.push request
    request
  end

  # run multiple requests in parallel
  def run
    hydra = Typhoeus::Hydra.hydra
    @requests.each{ |request| hydra.queue request }
    hydra.run
  end

end


Typhoeus.configure do |config|
  config.verbose = false
end

def get_my_request base_url, forbid_reuse_val, &block
  request = Typhoeus::Request.new(base_url, forbid_reuse: forbid_reuse_val)
  request.on_complete { |response| yield response } if block
  request
end

def self.memory_usage
  `ps -o rss= -p #{Process.pid}`.to_i
end

requests_per_iteration_one = 2
requests_per_iteration_two = 2
single_requests_per_iteration = 2
forbid_reuse_val = true
memory_interval = 10
j = 1

1_000.times do
  multi_requests_one = Requests::new
  req1 = get_my_request "http://www.google.com/#q=stuff#{j}", forbid_reuse_val do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  req2 =  get_my_request "http://www.bing.com/search?q=stuff#{j}", forbid_reuse_val do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  req3 = get_my_request "http://www.google.com/#q=sturf#{j*1000}", forbid_reuse_val do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  req4 = get_my_request "http://www.bing.com/search?q=sturf#{j*1000}", forbid_reuse_val do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  multi_requests_one.add(req1)
  multi_requests_one.add(req2)
  multi_requests_one.add(req3)
  multi_requests_one.add(req4)
  puts "running multi_requests_one #{j}"
  multi_requests_one.run

  multi_requests_two = Requests::new
  req1 = get_my_request"http://search.aol.com/aol/search?q=stuff#{j}", forbid_reuse_val  do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  req2 = get_my_request"http://www.yelp.com/search?find_desc=Thai-#{j}", forbid_reuse_val  do |response|
    puts "----------------------#{response.body.length} #{response.request.url}"
  end
  multi_requests_two.add(req1)
  multi_requests_two.add(req2)
  puts "running multi_requests_two #{j}"
  multi_requests_two.run

  single_requests_per_iteration.times do |k|
    base_url = "http://www.google.com/#q=stiff#{j+k}"
    request = get_my_request base_url, forbid_reuse_val  do |response|
      puts "----------------------#{response.body.length} #{response.request.url}"
    end
    puts "running single_requests #{j} #{k}"
    request.run
  end
  iteration = (j+=single_requests_per_iteration)/single_requests_per_iteration
  kilos = memory_usage if (iteration % memory_interval) == 0
  puts "#{iteration}- Memory usage: #{kilos/1024} MB - #{kilos} KB | PID: #{Process.pid}" if (iteration % memory_interval) == 0
  GC.start
end
