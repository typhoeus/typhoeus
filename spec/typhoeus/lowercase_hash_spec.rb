require File.dirname(__FILE__) + "/../spec_helper"

describe Typhoeus::LowercaseHash do
  before(:all) do
    @klass = Typhoeus::LowercaseHash
  end

  it "should normalize keys to lowercase" do
    hash = @klass.new
    hash['Content-Type'] = 'text/html'
    hash['content-type'].should == 'text/html'
    hash['Accepts'] = 'text/javascript'
    hash['accepts'].should == 'text/javascript'
  end

  it "should lowercase the keys" do
    hash = @klass.new('Content-Type' => 'text/html')
    hash.keys.should == ['content-type']
  end

  it "should merge keys correctly" do
    hash = @klass.new
    hash.merge!('Content-Type' => 'fdsa')
    hash['content-type'].should == 'fdsa'
  end

  it "should allow any casing of keys" do
    hash = @klass.new
    hash['Content-Type'] = 'fdsa'
    hash['content-type'].should == 'fdsa'
    hash['cOnTent-TYPE'].should == 'fdsa'
    hash['Content-Type'].should == 'fdsa'
  end

  it "should support has_key?" do
    hash = @klass.new
    hash['Content-Type'] = 'fdsa'
    hash.has_key?('cOntent-Type').should be_true
  end
end
