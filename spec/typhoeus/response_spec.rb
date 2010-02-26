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
  
  describe "headers" do
    it "can parse the headers into a hash" do
      response = Typhoeus::Response.new(:headers => "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\nStatus: 200\r\nX-Powered-By: Phusion Passenger (mod_rails/mod_rack) 2.2.9\r\nX-Cache: miss\r\nX-Runtime: 184\r\nETag: e001d08d9354ab7bc7c27a00163a3afa\r\nCache-Control: private, max-age=0, must-revalidate\r\nContent-Length: 4725\r\nSet-Cookie: _some_session=BAh7CDoGciIAOg9zZXNzaW9uX2lkIiU1OTQ2OTcwMjljMWM5ZTQwODU1NjQwYTViMmQxMTkxMjoGcyIKL2NhcnQ%3D--b4c4663932243090c961bb93d4ad5e4327064730; path=/; HttpOnly\r\nServer: nginx/0.6.37 + Phusion Passenger 2.2.4 (mod_rails/mod_rack)\r\nP3P: CP=\"NOI DSP COR NID ADMa OPTa OUR NOR\"\r\n\r\n")
      response.headers_hash["Status"].should == "200"
      response.headers_hash["Set-Cookie"].should == "_some_session=BAh7CDoGciIAOg9zZXNzaW9uX2lkIiU1OTQ2OTcwMjljMWM5ZTQwODU1NjQwYTViMmQxMTkxMjoGcyIKL2NhcnQ%3D--b4c4663932243090c961bb93d4ad5e4327064730; path=/; HttpOnly"
      response.headers_hash["Content-Type"].should == "text/html; charset=utf-8"
    end
  end
end
