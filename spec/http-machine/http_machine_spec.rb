require File.dirname(__FILE__) + '/../spec_helper'

describe HTTPMachine do
  it "should hit a local server" do
    run_local_server("result_set.xml") do
    end
  end
end