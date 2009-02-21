require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine::IsolatedBlock do
  before(:each) do
  end
  
  it "should not allow access to variables outside of those passed in" do
    @should_not_be_able_to_modify = "original"
    HTTPMachine::IsolatedBlock.run_isolated do
      @should_not_be_able_to_modify = "modified"
    end
    @should_not_be_able_to_modify.should == "original"
  end
  
  it "should take an arbitrary number of arguments that are accessible within the block" do
    call_mock = mock("call")
    call_mock.should_receive(:call)
    HTTPMachine::IsolatedBlock.run_isolated(call_mock) do
      call_mock.call
    end
  end
  
  it "should not allow the modification of any of the passed in arguments" do
    should_not_be_able_to_modify = "original"
    HTTPMachine::IsolatedBlock.run_isolated(should_not_be_able_to_modify) do
      should_not_be_able_to_modify.frozen?.should == true
    end
  end
  
  it "should unfreeze passed in objects after being called" do
    should_modifiy_after_call = "original"
    HTTPMachine::IsolatedBlock.run_isolated(should_modifiy_after_call) do
      should_modifiy_after_call.frozen?.should == true
    end
    should_modifiy_after_call.replace("modified")
    should_modifiy_after_call.should == "modified"    
  end
  
  it "should return an object"
end