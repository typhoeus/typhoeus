require File.dirname(__FILE__) + "/../spec_helper"

describe Typhoeus::HydraMock do
  it "should mark all responses as mocks" do
    response = Typhoeus::Response.new(:mock => false)
    response.should_not be_mock

    mock = Typhoeus::HydraMock.new("http://localhost", :get)
    mock.and_return(response)

    mock.response.should be_mock
    response.should be_mock
  end

  describe "stubbing response values" do
    before(:each) do
      @stub = Typhoeus::HydraMock.new('http://localhost:3000', :get)
    end

    describe "with a single response" do
      it "should always return that response" do
        response = Typhoeus::Response.new
        @stub.and_return(response)

        5.times do
          @stub.response.should == response
        end
      end
    end

    describe "with multiple responses" do
      it "should return consecutive responses in the array, then keep returning the last one" do
        responses = []
        3.times do |i|
          responses << Typhoeus::Response.new(:body => "response #{i}")
        end

        # Stub 3 consecutive responses.
        @stub.and_return(responses)

        0.upto(2) do |i|
          @stub.response.should == responses[i]
        end

        5.times do
          @stub.response.should == responses.last
        end
      end
    end
  end

  describe "#matches?" do
    describe "basic matching" do
      it "should not match if the HTTP verbs are different" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get)
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :post)
        mock.matches?(request).should be_false
      end
    end

    describe "matching on ports" do
      it "should handle default port 80 sanely" do
        mock = Typhoeus::HydraMock.new('http://www.example.com:80/', :get,
                                       :headers => { 'user-agent' => 'test' })
        request = Typhoeus::Request.new('http://www.example.com/',
                                        :method => :get,
                                        :user_agent => 'test')
        mock.matches?(request).should be_true
      end

      it "should handle default port 443 sanely" do
        mock = Typhoeus::HydraMock.new('https://www.example.com:443/', :get,
                                       :headers => { 'user-agent' => 'test' })
        request = Typhoeus::Request.new('https://www.example.com/',
                                        :method => :get,
                                        :user_agent => 'test')
        mock.matches?(request).should be_true
      end
    end


    describe "any HTTP verb" do
      it "should match any verb" do
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :any,
                                       :headers => { 'user-agent' => 'test' })
        [:get, :post, :delete, :put].each do |verb|
          request = Typhoeus::Request.new("http://localhost:3000",
                                          :method => verb,
                                          :user_agent => 'test')
          mock.matches?(request).should be_true
        end
      end
    end

    describe "header matching" do
      it "should return false if headers is set and request has no headers" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => {})
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'fdsa' => 'fdsa' })
        mock.matches?(request).should be_false
      end

      it "should return true if headers is nil and the request doesn't have headers" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get)
        request.stub!(:headers).and_return(nil)
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => nil)
        mock.matches?(request).should be_true
      end

      it "should handle multiple values for headers" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :headers => {
                                          'Accept' => ['text/html', 'application/csv']
                                        })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :any,
                                       :headers => {
                                          'Accept' => ['application/csv', 'text/html'],
                                          'User-Agent' => 'test'
                                       })

        mock.matches?(request).should be_true
      end

      it "should fail with incorrect multiple values" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :headers => {
                                          'Accept' => ['text/html']
                                        })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :any,
                                       :headers => {
                                          'Accept' => ['text/html', 'application/csv'],
                                          'User-Agent' => 'test'
                                       })

        mock.matches?(request).should be_false
      end

      it "should not match if the headers do not match" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => { 'Content-Type' => 'text/html' })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => 'fdsafdsa',
                                       :headers => { 'Content-Type' => 'text/html', 'Another' => 'fdsa' })
        mock.matches?(request).should be_false
      end

      it "should match if there are more headers in the request" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => { 'Content-Type' => 'text/html', 'Extra' => 'fdsa' })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'Content-Type' => 'text/html' })
        mock.matches?(request).should be_true
      end

      it "should match on lowercase header keys" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => { 'Content-Type' => 'text/html' })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'content-type' => 'text/html', 'User-Agent' => request.user_agent })
        mock.matches?(request).should be_true
      end

      it "should match on exact headers" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => { 'Content-Type' => 'text/html' })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'Content-Type' => 'text/html', 'User-Agent' => request.user_agent })
        mock.matches?(request).should be_true
      end

      it "should not match if the request has headers, but the mock does not have headers" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :headers => { 'Content-Type' => 'text/html' })
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get)
        mock.matches?(request).should be_false
      end
    end

    describe "post body matching" do
      it "should not bother matching on body if we don't turn the option on" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'user-agent' => 'test' })
        mock.matches?(request).should be_true
      end

      it "should match nil correctly" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => nil)
        mock.matches?(request).should be_false
      end

      it "should not match if the bodies do not match" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :body => "ffdsadsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => 'fdsafdsa')
        mock.matches?(request).should be_false
      end

      it "should match on optional body parameter" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => 'fdsafdsa',
                                       :headers => {
                                         'User-Agent' => 'test'
                                       })
        mock.matches?(request).should be_true
      end

      it "should regex match" do
        request = Typhoeus::Request.new("http://localhost:3000/whatever/fdsa",
                                        :method => :get,
                                        :user_agent => 'test')
        mock = Typhoeus::HydraMock.new(/fdsa/, :get,
                                       :headers => { 'user-agent' => 'test' })
        mock.matches?(request).should be_true
      end
    end
  end
end

