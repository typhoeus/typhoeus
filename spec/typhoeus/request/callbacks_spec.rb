# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request::Callbacks do
  let(:request) { Typhoeus::Request.new("fubar") }

  [:on_complete, :on_success, :on_failure, :on_progress].each do |callback|
    describe "##{callback}" do
      it "responds" do
        expect(request).to respond_to(callback)
      end

      context "when no block given" do
        it "returns @#{callback}" do
          expect(request.method(callback).call).to eq([])
        end
      end

      context "when block given" do
        it "stores" do
          request.method(callback).call { p 1 }
          expect(request.instance_variable_get("@#{callback}").size).to eq(1)
        end
      end

      context "when multiple blocks given" do
        it "stores" do
          request.method(callback).call { p 1 }
          request.method(callback).call { p 2 }
          expect(request.instance_variable_get("@#{callback}").size).to eq(2)
        end
      end
    end
  end

  describe "#execute_callbacks" do
    [:on_complete, :on_success, :on_failure].each do |callback|
      context "when #{callback}" do
        let(:response_code) { callback == :on_failure ? 500 : 200 }
        let(:response) do
          Typhoeus::Response.new(:mock => true, :response_code => response_code)
        end
        let(:calls) { [] }

        before { request.response = response }

        context "when local callback" do
          before { request.method(callback).call { |r| calls << r } }

          it "executes blocks and passes response" do
            request.execute_callbacks

            expect(calls).to eq([response])
          end

          it "sets handled_response" do
            request.method(callback).call { 1 }
            request.execute_callbacks
            expect(request.response.handled_response).to be(1)
          end
        end

        context "when global callback" do
          before { Typhoeus.method(callback).call { |r| calls << r } }

          it "executes blocks and passes response" do
            request.execute_callbacks

            expect(calls).to eq([response])
          end
        end

        context "when global and local callbacks" do
          before do
            Typhoeus.method(callback).call { |r| calls << :global; r.instance_variable_set(:@fu, 1) }
            request.method(callback).call { |r| calls << :local; expect(r.instance_variable_get(:@fu)).to eq(1) }
          end

          it "runs global first" do
            request.execute_callbacks

            expect(calls).to eq([:global, :local])
          end
        end
      end
    end

    context "when on_progress" do
      it "is not executed on completion" do
        response = Typhoeus::Response.new(:mock => true, :response_code => 200)
        request.response = response
        request.on_progress { raise "local progress ran on completion" }
        Typhoeus.on_progress { raise "global progress ran on completion" }

        expect { request.execute_callbacks }.not_to raise_error
        expect(response.handled_response).to be(response)
      end
    end

    context "when local on_complete and global on_success" do
      it "runs on_complete callbacks before on_success callbacks" do
        request.response = Typhoeus::Response.new(:mock => true, :response_code => 200)
        order = []
        Typhoeus.on_complete { order << :global_complete }
        request.on_complete { order << :local_complete }
        Typhoeus.on_success { order << :global_success }
        request.on_success { order << :local_success }

        request.execute_callbacks

        expect(order).to eq(
          [:global_complete, :local_complete, :global_success, :local_success]
        )
      end
    end
  end
end
