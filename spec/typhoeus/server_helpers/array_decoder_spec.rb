require 'spec_helper'
require 'typhoeus/server_helpers/array_decoder'

describe Typhoeus::ServerHelpers::ArrayDecoder do
  let(:controller){ControllerStub.new}

  describe "#deep_decode!" do

    example "converts {'0' => '0val', '1' => '1val'} to ['0val','1val']" do
      params = {:array => {'0' => '0val', '1' => '1val'}}
      controller.deep_decode!(params)
      params[:array].should == ['0val','1val']
    end

    it "modifies given hash" do
      params = {:array => {'0' => 'value'}}
      controller.deep_decode!(params)
      params[:array].should == ['value']
    end


    it "keeps non typhoeus-arrays hashes unmodified" do
      params = {:non_array => {'k1' => 12, 'k2' => 13}, :typho_array => { '0' => 'asdf'} }
      controller.deep_decode!(params)
      params[:non_array].should == {'k1' => 12, 'k2' => 13}
      params[:typho_array].should == ['asdf']
    end

    it "keeps values unmodified" do
      params = {:array => {'0' => 0, '1' => '1', '2' => 'asdfa', '3' => controller}}
      controller.deep_decode!(params)
      params[:array].should == [0,'1','asdfa', controller]
    end

    it "decodes nested arrays" do
      params = {:array => {'0' => 0, '1' => {'0' => 'sub0', '1' => 'sub1', '2' => {'0' => 'subsub0'}}}}
      controller.deep_decode!(params)
      params[:array].should == [0,['sub0','sub1',['subsub0']]]
    end
  end

  describe "#deep_decode" do
    it "works like deep_decode! converting arrays" do
      params = {:array => {'0' => '0val', '1' => '1val'}}
      new_params = controller.deep_decode(params)
      new_params[:array].should == ['0val','1val']
    end

    it "leaves given hash unmodified and returns modified version" do
      params = {:array => {'0' => '0val', '1' => '1val'}}
      new_params = controller.deep_decode(params)
      params.should == {:array => {'0' => '0val', '1' => '1val'}}
      new_params[:array].should == ['0val','1val']
    end
  end

end

class ControllerStub
  include Typhoeus::ServerHelpers::ArrayDecoder
  def initialize
  end
end