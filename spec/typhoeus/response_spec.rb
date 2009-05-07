require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::Response do
  describe "initialize" do
    it "should store response_code" do
      Typhoeus::Response.new(200, nil, nil, nil).code.should == 200
    end
    
    it "should store response_headers" do
      Typhoeus::Response.new(nil, "a header!", nil, nil).headers.should == "a header!"
    end
    
    it "should store response_body" do
      Typhoeus::Response.new(nil, nil, "a body!", nil).body.should == "a body!"
    end
    
    it "should store request_time" do
      Typhoeus::Response.new(nil, nil, nil, 1.23).time.should == 1.23
    end
  end
end