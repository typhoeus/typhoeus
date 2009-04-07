require File.dirname(__FILE__) + '/../lib/http-machine.rb'

class Twitter
  include HTTPMachine
  remote_method :search, 
    :server => "http://search.twitter.com/search.json", 
    :method => :get,
    :response_type => :json
end
