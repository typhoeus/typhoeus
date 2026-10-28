# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request do
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

          it "returns the callback's response" do
            response = Typhoeus::Response.new
            Typhoeus.before { response }
            expect(request.run).to be(response)
          end

          it "assigns the callback's response to the request" do
            response = Typhoeus::Response.new
            Typhoeus.before { response }
            request.run
            expect(request.response).to be(response)
          end

          it "runs the completion callbacks" do
            response = Typhoeus::Response.new
            Typhoeus.before { response }
            expect(receive_counter).to receive(:mark)
            request.on_complete { |_| receive_counter.mark }
            request.run
          end

          it "treats a synthetic response as a mock" do
            response = Typhoeus::Response.new(:code => 200)
            Typhoeus.before { response }
            request.run

            expect(response.mock).to be(true)
            expect(response.success?).to be(true)
          end

          it "doesn't cache a synthetic response" do
            cache = double("cache", :get => nil)
            expect(cache).not_to receive(:set)
            Typhoeus::Config.cache = cache
            Typhoeus.before { Typhoeus::Response.new(:code => 200) }

            request.run
          end

          it "treats a reused response as a mock" do
            response = Typhoeus::Response.new(:code => 200)
            response.request = Typhoeus::Request.new("www.example.com")
            Typhoeus.before { response }

            request.run

            expect(response.mock).to be(true)
            expect(response.success?).to be(true)
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

        it "returns the callback's response" do
          response = Typhoeus::Response.new
          request.before { response }
          expect(request.run).to be(response)
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

    context "when before is excluded" do
      before { Typhoeus::Config.exclude_features = [:before] }

      it "does not run global callbacks" do
        Typhoeus.before { raise "should not be called" }

        expect(Typhoeus::Expectation).to receive(:response_for).and_return(nil)
        request.run
      end

      it "does not run request callbacks" do
        request.before { raise "should not be called" }

        expect(Typhoeus::Expectation).to receive(:response_for).and_return(nil)
        request.run
      end
    end
  end
end
