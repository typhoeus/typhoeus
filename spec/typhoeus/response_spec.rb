require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus::Response do
  describe "initialize" do
    it "should store response_code" do
      Typhoeus::Response.new(:code => 200).code.should == 200
    end
    
    it "should store response_headers" do
      Typhoeus::Response.new(:headers => "a header!").headers.should == "a header!"
    end
    
    it "should store response_body" do
      Typhoeus::Response.new(:body => "a body!").body.should == "a body!"
    end
    
    it "should store request_time" do
      Typhoeus::Response.new(:time => 1.23).time.should == 1.23
    end

    it "should store requested_url" do
      response = Typhoeus::Response.new(:requested_url => "http://test.com")
      response.requested_url.should == "http://test.com"
    end

    it "should store requested_http_method" do
      response = Typhoeus::Response.new(:requested_http_method => :delete)
      response.requested_http_method.should == :delete
    end
    
    it "should store an associated request object" do
      response = Typhoeus::Response.new(:request => "whatever")
      response.request.should == "whatever"
    end
  end
end
