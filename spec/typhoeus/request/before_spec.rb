require 'spec_helper'

describe Typhoeus::Request::Before do
  let(:request) { Typhoeus::Request.new("") }

  after { Typhoeus.before.clear }

  describe "#queue" do
    context "when before" do
      context "when one" do
        it "executes" do
          Typhoeus.before { |r| String.new(r.url) }
          String.should_receive(:new).and_return("")
          request.run
        end

        context "when true" do
          it "calls super" do
            Typhoeus.before { true }
            Typhoeus::Expectation.should_receive(:find_by)
            request.run
          end
        end

        context "when false" do
          it "doesn't call super" do
            Typhoeus.before { false }
            Typhoeus::Expectation.should_receive(:find_by).never
            request.run
          end
        end
      end

      context "when multi" do
        context "when all true" do
          before { 3.times { Typhoeus.before { |r| String.new(r.url) } } }

          it "calls super" do
            Typhoeus::Expectation.should_receive(:find_by)
            request.run
          end

          it "executes all" do
            String.should_receive(:new).exactly(3).times.and_return("")
            request.run
          end
        end

        context "when middle false" do
          before do
            Typhoeus.before { |r| String.new(r.url) }
            Typhoeus.before { |r| String.new(r.url); nil }
            Typhoeus.before { |r| String.new(r.url) }
          end

          it "doesn't call super" do
            Typhoeus::Expectation.should_receive(:find_by).never
            request.run
          end

          it "executes only two" do
            String.should_receive(:new).exactly(2).times.and_return("")
            request.run
          end
        end
      end
    end

    context "when no before" do
      it "calls super" do
        Typhoeus::Expectation.should_receive(:find_by)
        request.run
      end
    end
  end
end
