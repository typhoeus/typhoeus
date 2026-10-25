# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Config do
  let(:config) { Typhoeus::Config }

  [:block_connection, :memoize, :verbose, :cache, :user_agent, :proxy, :max_idle_easies].each do |name|
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
end
