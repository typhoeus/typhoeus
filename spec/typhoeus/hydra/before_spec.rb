# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Hydra do
  let(:request) { Typhoeus::Request.new("") }
  let(:hydra) { Typhoeus::Hydra.new }
  let(:receive_counter) { double :mark => :twain }

  describe "#add" do
    context "when before" do
      context "when one" do
        it "executes" do
          Typhoeus.before { |r| receive_counter.mark }
          expect(receive_counter).to receive(:mark)
          hydra.add(request)
        end

        context "when true" do
          it "calls super" do
            Typhoeus.before { true }
            expect(Typhoeus::Expectation).to receive(:response_for)
            hydra.add(request)
          end
        end

        context "when falsy" do
          context "when queue requests" do
            let(:queued_request) { Typhoeus::Request.new("") }

            before { hydra.queue(queued_request) }

            it "dequeues" do
              Typhoeus.before { false }
              hydra.add(request)
              expect(hydra.queued_requests).to be_empty
            end
          end

          context "when false" do
            it "doesn't call super" do
              Typhoeus.before { false }
              expect(Typhoeus::Expectation).to receive(:response_for).never
              hydra.add(request)
            end
          end

          context "when response" do
            it "doesn't call super" do
              Typhoeus.before { Typhoeus::Response.new }
              expect(Typhoeus::Expectation).to receive(:response_for).never
              hydra.add(request)
            end

            it "finishes the request with the response" do
              response = Typhoeus::Response.new
              Typhoeus.before { response }
              hydra.add(request)
              expect(request.response).to be(response)
            end

            it "runs the completion callbacks" do
              Typhoeus.before { Typhoeus::Response.new }
              expect(receive_counter).to receive(:mark)
              request.on_complete { |_| receive_counter.mark }
              hydra.add(request)
            end
          end
        end
      end

      context "when one local" do
        it "executes" do
          request.before { |r| receive_counter.mark }
          expect(receive_counter).to receive(:mark)
          hydra.add(request)
        end

        context "when false" do
          it "does not call super" do
            request.before { false }
            expect(Typhoeus::Expectation).to receive(:response_for).never
            hydra.add(request)
          end
        end
      end

      context "when one local and one global" do
        it "executes both" do
          Typhoeus.before { |r| receive_counter.mark }
          request.before { |r| receive_counter.mark }
          expect(receive_counter).to receive(:mark).twice
          hydra.add(request)
        end
      end

      context "when multiple" do
        before { 2.times { request.before { |r| receive_counter.mark } } }

        it "executes all" do
          expect(receive_counter).to receive(:mark).exactly(2).times
          hydra.add(request)
        end
      end

      context "when multi" do
        context "when all true" do
          before { 3.times { Typhoeus.before { |r| receive_counter.mark } } }

          it "calls super" do
            expect(Typhoeus::Expectation).to receive(:response_for)
            hydra.add(request)
          end

          it "executes all" do
            expect(receive_counter).to receive(:mark).exactly(3).times
            hydra.add(request)
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
            hydra.add(request)
          end

          it "executes only two" do
            expect(receive_counter).to receive(:mark).exactly(2).times
            hydra.add(request)
          end
        end
      end
    end

    context "when no before" do
      it "calls super" do
        expect(Typhoeus::Expectation).to receive(:response_for)
        hydra.add(request)
      end
    end

    context "when before is excluded" do
      before { Typhoeus::Config.exclude_features = [:before] }

      it "does not run global callbacks" do
        Typhoeus.before { |request| request.finish(Typhoeus::Response.new) }

        hydra.add(request)

        expect(request.response).to be_nil
      end

      it "does not run request callbacks" do
        request.before { |request| request.finish(Typhoeus::Response.new) }

        hydra.add(request)

        expect(request.response).to be_nil
      end

      it "still adds the request to the multi" do
        expect(Typhoeus::EasyFactory).to receive(:new).and_call_original

        hydra.add(request)
      end
    end
  end
end

