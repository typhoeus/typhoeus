require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::Easy do
  before(:all) do
    @pid = start_method_server(3002)
  end
  
  after(:all) do
    stop_method_server(@pid)
  end
  
  it "should be reusable" do
    easy = HTTPMachine::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    
    multi = HTTPMachine::Multi.new
    multi.add(easy)
    multi.perform
    easy.response_code.should == 200
    easy.response_body.should include("METHOD=GET")
    
    e2 = HTTPMachine::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    multi.add(e2)
    multi.perform
    
    e2.response_code.should == 200
    e2.response_body.should include("METHOD=POST")
  end
  
  it "should perform easy handles added after the first one runs" do
    easy = HTTPMachine::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    multi = HTTPMachine::Multi.new
    multi.add(easy)

    e2 = HTTPMachine::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    easy.on_success do |e|
      multi.add(e2)
    end
    
    multi.perform
    easy.response_code.should == 200
    easy.response_body.should include("METHOD=GET")    
    e2.response_code.should == 200
    e2.response_body.should include("METHOD=POST")    
  end
  
  # it "should do multiple gets" do
    # multi = HTTPMachine::Multi.new
    # 
    # handles = []
    # 5.times do |i|
    #   easy = HTTPMachine::Easy.new
    #   easy.url = "http://localhost:3002"
    #   easy.method = :get
    #   easy.on_success {|e| puts "get #{i} succeeded"}
    #   easy.on_failure {|e| puts "get #{i} failed with #{e.response_code}"}
    #   handles << easy
    #   multi.add(easy)
    # end
    # 
    # multi.perform
  # end
end