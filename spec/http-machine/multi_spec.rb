require File.dirname(__FILE__) + '/../spec_helper'

require 'rubygems'
require 'curb'
describe HTTPMachine::Easy do
  before(:all) do
    @pid = start_method_server(3002)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end
  
  it "should do multiple gets" do
    # m = Curl::Multi.new
    # c = Curl::Easy.new("http://localhost:4567")
    # c.on_success do |c|
    #   puts c.body_str
    # end
    # 
    # c.on_failure do |c|
    #   puts c.header_str
    #   puts c.response_code
    # end
    # m.add(c)
    # m.perform
    
    multi = HTTPMachine::Multi.new

    handles = []
    5.times do |i|
      easy = HTTPMachine::Easy.new
      easy.url = "http://localhost:3002"
      easy.method = :get
      easy.on_success {|e| puts "get #{i} succeeded"}
      easy.on_failure {|e| puts "get #{i} failed with #{e.response_code}"}
      handles << easy
      multi.add(easy)
    end

    multi.perform
#    easy.response_body.should == ''
  end
end