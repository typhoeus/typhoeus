require 'spec_helper'

describe Typhoeus do
  describe ".configure" do
    it "yields config" do
      Typhoeus.configure do |config|
        config.should be_a(Typhoeus::Config)
      end
    end

    it "sets values config" do
      Typhoeus.configure { |config| config.verbose = true }
      Typhoeus::Config.verbose.should be_true
    end
  end
end
