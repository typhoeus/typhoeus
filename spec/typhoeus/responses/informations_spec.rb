require 'spec_helper'

describe Typhoeus::Responses::Informations do
  let(:response) { Typhoeus::Response.new }
  Typhoeus::Responses::Informations::AVAILABLE_INFORMATIONS.each do |name|
    describe name do
      it "responds to" do
        response.should respond_to(name)
      end
    end
  end
end
