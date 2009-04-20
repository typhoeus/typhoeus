require File.dirname(__FILE__) + '/../spec_helper'

describe Typhoeus do
  it "should store a block to be executed later after service_access runs" do
    val = nil
    Typhoeus.add_after_service_access_callback do
      val = :foo
    end
    Typhoeus.service_access {}
    val.should == :foo
  end
end