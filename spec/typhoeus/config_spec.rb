# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Config do
  let(:config) { Typhoeus::Config }

  [:block_connection, :memoize, :verbose, :cache, :exclude_features, :user_agent, :proxy, :max_idle_easies].each do |name|
    it "responds to #{name}" do
      expect(config).to respond_to(name)
    end

    it "responds to #{name}=" do
      expect(config).to respond_to("#{name}=")
    end
  end

  it "defaults max_idle_easies to 20" do
    expect(config.max_idle_easies).to eq(20)
  end

  describe ".max_idle_easies=" do
    it "accepts nil" do
      config.max_idle_easies = nil

      expect(config.max_idle_easies).to be_nil
    end

    it "accepts zero" do
      config.max_idle_easies = 0

      expect(config.max_idle_easies).to eq(0)
    end

    it "rejects negative values" do
      expect { config.max_idle_easies = -1 }.to raise_error(
        ArgumentError,
        /max_idle_easies/
      )
    end

    it "rejects values that are not integers" do
      expect { config.max_idle_easies = "20" }.to raise_error(
        ArgumentError,
        /max_idle_easies/
      )
    end
  end
end
