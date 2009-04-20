require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine do
  it "should store a block to be executed later after service_access runs" do
    val = nil
    HTTPMachine.add_after_service_access_callback do
      val = :foo
    end
    HTTPMachine.service_access {}
    val.should == :foo
  end
end