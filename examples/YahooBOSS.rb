require File.dirname(__FILE__) + '/../lib/http-machine.rb'
require 'sax-machine'

class YahooBOSS < HTTPMachine::Remote  
  API_ID = "..."
  
  remote_server "http://boss.yahooapis.com"
  remote_method :web_search,  {
    :resource => "ysearch/web/v1",
    :method => :get, 
    :params => {:appid => API_ID, :format => "xml", :view => "keyterms", :abstract => "long", :count => 100},
    :response_handler => :parse }  
  remote_method :site_search, {
    :resource => "ysearch/se_inlink/v1/", 
    :method => :get, 
    :params => {:appid => API_ID, :format => "xml"}, 
    :response_handler => :parse }

  include SAXMachine
  class Result
    include SAXMachine
    element :abstract
    element :date
    element :title
    element :url
    elements :term, :as => :terms
    
    def date=(value)
      @date = Date.parse(value)
    end
  end
  elements :result, :as => :results, :class => Result
  
  element :nextpage, :as => :next_page
  element :resultset_web,       :value => :totalhits, :as => :total_hits
  element :resultset_web,       :value => :deephits,  :as => :deep_hits
  element :resultset_se_inlink, :value => :totalhits, :as => :total_hits
  element :resultset_se_inlink, :value => :deephits,  :as => :deep_hits
end