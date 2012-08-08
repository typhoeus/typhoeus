require 'spec_helper'

describe Typhoeus::Config do
  let(:config) { Typhoeus::Config }

  [:verbose, :memoize, :fake].each do |name|
    it "responds to #{name}" do
      expect(config).to respond_to(name)
    end

    it "responds to #{name}=" do
      expect(config).to respond_to("#{name}=")
    end
  end
end
