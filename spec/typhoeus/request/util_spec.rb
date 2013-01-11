require 'spec_helper'

describe Typhoeus::Request::Util do
  let(:params) { {:foo => 123, :bar => '!! test !!', :zing => nil} }
  let(:request) { Typhoeus::Request.new({}) }

  describe ".escape" do
    it "should pass argument.to_s to URI.encode_www_form_component" do
      value = "string"
      value.should_receive(:to_s)
      URI.should_receive(:encode_www_form_component)
      request.escape(value)
    end
  end
          
  describe ".build_query" do
    it "should escape keys and values" do
      params = {:foo => 1}
      request.should_receive(:escape).with(:foo).and_call_original
      request.should_receive(:escape).with(1).and_call_original      
      expect(request.build_query(params)).to eq("foo=1")
    end
    
    it "should not try to escape nil values" do
      params = {:foo => nil}
      request.should_receive(:escape).with(:foo).and_call_original
      expect(request.build_query(params)).to eq("foo=")      
    end
    
    it "should recurse when a value is an array" do
      params = {:foo => [1,2]}
      request.should_receive(:escape).with(:foo).twice.and_call_original
      request.should_receive(:escape).with(1).and_call_original
      request.should_receive(:escape).with(2).and_call_original            
      expect(request.build_query(params)).to eq("foo=1&foo=2")      
    end
  end
  
  describe ".sort_params" do
    it "should sort params on key" do
      expect(request.sort_params(params).map(&:first)).to eq([:bar,:foo,:zing])
    end
  end  
  
  describe ".explode_query_string" do
    it "should explode a query string in to an array" do
      query_string = "a=1&b=2&c=&d=3"
      expected = [["a", "1"], ["b", "2"], ["c"], ["d", "3"]]
      expect(request.explode_query_string(query_string)).to eq(expected)
    end
  end
      
  describe ".param_pairs" do
    it "should create pairs using only option params" do
      request.should_receive(:options).twice.and_return({:params => params})
      expected = [[:foo, 123], [:bar, "!! test !!"], [:zing, nil]]
      expect(request.param_pairs('')).to eq(expected)
    end
    
    it "should create pairs using only supplied base url params" do
      expected = [["a", "1"], ["b", "2"], ["c"], ["d", "3"]]
      expect(request.param_pairs('a=1&b=2&c=&d=3')).to eq(expected)
    end

    it "should create pairs combining option and base url params" do
      request.should_receive(:options).twice.and_return({:params => params})
      expected = [["a","1"], ["b","2"], [:foo, 123], [:bar, "!! test !!"], [:zing, nil]]
      expect(request.param_pairs('a=1&b=2')).to eq(expected)
    end
  end
    
  describe ".url" do
    it "creates urls with sorted parameters" do
      base_url = "localhost:3001"
      response = Typhoeus::Request.new(base_url, :params => params)
      expected = "#{base_url}?bar=%21%21+test+%21%21&foo=123&zing="
      expect(response.url).to eq(expected)
    end

    it "creates urls with sorted parameters and combines them with existing base_url parameters" do
      base_url = "localhost:3001?xyz=456"
      response = Typhoeus::Request.new(base_url, :params => params)
      expected = "localhost:3001?bar=%21%21+test+%21%21&foo=123&xyz=456&zing="
      expect(response.url).to eq(expected)
    end
  end
end

