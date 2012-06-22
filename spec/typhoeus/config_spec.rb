require 'spec_helper'

describe Typhoeus::Config do
  let(:config) { Typhoeus::Config }

  [:verbose, :memoize].each do |name|
    it "responds to #{name}" do
      config.should respond_to(name)
    end

    it "responds to #{name}=" do
      config.should respond_to("#{name}=")
    end
  end
end
