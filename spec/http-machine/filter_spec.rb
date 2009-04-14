require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::Filter do
  it "should take options and a block on new" do
    filter = HTTPMachine::Filter.new({}, lambda {})
    filter.should_not be_nil
  end
  
  it "should be able to call the passed in block" do
    block = mock("block_mock")
    block.should_receive(:called)
    filter = HTTPMachine::Filter.new({}, lambda {block.called})
    filter.call(:foo)
  end

  describe "#apply_filter?" do
    it "should return true for any method when :only and :except aren't specified" do
      filter = HTTPMachine::Filter.new({}, lambda {})
      filter.apply_filter?(:asdf).should be_true
    end
    
    it "should return true if a method is in only" do
      filter = HTTPMachine::Filter.new({:only => :foo}, lambda {})
      filter.apply_filter?(:foo).should be_true
    end
    
    it "should return false if a method isn't in only" do
      filter = HTTPMachine::Filter.new({:only => :foo}, lambda {})
      filter.apply_filter?(:bar).should be_false
    end
    
    it "should return true if a method isn't in except" do
      filter = HTTPMachine::Filter.new({:except => :foo}, lambda {})
      filter.apply_filter?(:bar).should be_true
    end
    
    it "should return false if a method is in except" do
      filter = HTTPMachine::Filter.new({:except => :foo}, lambda {})
      filter.apply_filter?(:foo).should be_false
    end
  end
end