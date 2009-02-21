require File.dirname(__FILE__) + '/../lib/http-machine.rb'

class Twitter
  include HTTPMachine
  remote_server "http://search.twitter.com/search.json"
  remote_method :search,  {
    :resource => "ysearch/web/v1",
    :method => :get, 
    :response_handler => :parse }

  def self.parse(results)
    results
  end  
end

HTTPMachine.service_access do
  Twitter.search({:q => "pauldix"}) do |tweets|
    puts tweets
  end
end