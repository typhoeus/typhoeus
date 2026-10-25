# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request::Before do
  let(:request) { Typhoeus::Request.new("") }
  let(:receive_counter) { double :mark => :twain }

  describe "#before" do
    it "responds" do
      expect(request).to respond_to(:before)
    end

    context "when no block given" do
      it "returns an empty array" do
        expect(request.before).to eq([])
      end
    end

    context "when block given" do
      it "stores the block" do
        request.before { true }
        expect(request.before.size).to eq(1)
      end
    end
  end

  describe "#queue" do
    context "when before" do
      context "when one" do
        it "executes" do
          Typhoeus.before { |r| receive_counter.mark }
          expect(receive_counter).to receive(:mark)
          request.run
        end

        context "when true" do
          it "calls super" do
            Typhoeus.before { true }
            expect(Typhoeus::Expectation).to receive(:response_for)
            request.run
          end
        end

        context "when false" do
          it "doesn't call super" do
            Typhoeus.before { false }
            expect(Typhoeus::Expectation).to receive(:response_for).never
            request.run
          end

          it "returns response" do
            Typhoeus.before { |r| r.response = 1; false }
            expect(request.run).to be(1)
          end
        end

        context "when a response" do
          it "doesn't call super" do
            Typhoeus.before { Typhoeus::Response.new }
            expect(Typhoeus::Expectation).to receive(:response_for).never
            request.run
          end

          it "returns response" do
            Typhoeus.before { |r| r.response = Typhoeus::Response.new }
            expect(request.run).to be_a(Typhoeus::Response)
          end
        end
      end

      context "when one local" do
        it "executes" do
          request.before { |r| receive_counter.mark }
          expect(receive_counter).to receive(:mark)
          request.run
        end

        it "runs global callbacks first" do
          order = []
          Typhoeus.before { order << :global }
          request.before { order << :local; false }
          request.run
          expect(order).to eq([:global, :local])
        end

        context "when false" do
          it "doesn't call super" do
            request.before { false }
            expect(Typhoeus::Expectation).to receive(:response_for).never
            request.run
          end
        end
      end

      context "when multi" do
        context "when all true" do
          before { 3.times { Typhoeus.before { |r| receive_counter.mark } } }

          it "calls super" do
            expect(Typhoeus::Expectation).to receive(:response_for)
            request.run
          end

          it "executes all" do
            expect(receive_counter).to receive(:mark).exactly(3)
            request.run
          end
        end

        context "when middle false" do
          before do
            Typhoeus.before { |r| receive_counter.mark }
            Typhoeus.before { |r| receive_counter.mark; nil }
            Typhoeus.before { |r| receive_counter.mark }
          end

          it "doesn't call super" do
            expect(Typhoeus::Expectation).to receive(:response_for).never
            request.run
          end

          it "executes only two" do
            expect(receive_counter).to receive(:mark).exactly(2).times
            request.run
          end
        end
      end
    end

    context "when no before" do
      it "calls super" do
        expect(Typhoeus::Expectation).to receive(:response_for)
        request.run
      end
    end
  end
end
