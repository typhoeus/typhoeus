# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Request::Marshal do
  let(:base_url) { TestServer.host }
  let(:request) { Typhoeus::Request.new(base_url) }

  describe "#marshal_dump" do
    %w(on_complete on_success on_failure on_progress on_headers on_body).each do |name|
      context "when #{name} handler" do
        before { request.instance_variable_set("@#{name}", Proc.new{}) }

        it "doesn't include @#{name}" do
          expect(request.send(:marshal_dump).map(&:first)).to_not include("@#{name}")
        end

        it "doesn't raise when dumped" do
          expect { Marshal.dump(request) }.to_not raise_error
        end

        context "when loading" do
          let(:loaded) { Marshal.load(Marshal.dump(request)) }

          it "includes base_url" do
            expect(loaded.base_url).to eq(request.base_url)
          end

          it "doesn't include #{name}" do
            expect(loaded.instance_variables).to_not include("@#{name}")
          end
        end
      end
    end

    context "when before callbacks" do
      before { request.before { true } }

      it "doesn't include @before" do
        expect(request.send(:marshal_dump).map(&:first)).to_not include("@before")
      end

      it "doesn't raise when dumped" do
        expect { Marshal.dump(request) }.to_not raise_error
      end

      context "when loading" do
        let(:loaded) { Marshal.load(Marshal.dump(request)) }

        it "includes base_url" do
          expect(loaded.base_url).to eq(request.base_url)
        end

        it "doesn't include @before" do
          expect(loaded.instance_variables).to_not include("@before")
        end
      end
    end

    context "when the request ran" do
      before do
        Typhoeus.stub(base_url).and_return(
          Typhoeus::Response.new(:code => 200, :body => "response")
        )
        request.on_complete { |_| proc { } }
        request.run
      end

      it "doesn't include @response" do
        expect(request.send(:marshal_dump).map(&:first)).to_not include("@response")
      end

      it "dumps the completed request" do
        expect { Marshal.dump(request) }.to_not raise_error
      end

      context "when loading" do
        let(:loaded) { Marshal.load(Marshal.dump(request)) }

        it "includes base_url" do
          expect(loaded.base_url).to eq(request.base_url)
        end

        it "has no response" do
          expect(loaded.response).to be_nil
        end
      end
    end

    context 'when run through hydra' do
      let(:options) { {} }
      let(:hydra) { Typhoeus::Hydra.new(options) }

      before(:each) do
        hydra.queue(request)
        hydra.run
      end

      it "doesn't include @hydra" do
        expect(request.send(:marshal_dump).map(&:first)).to_not include("@hydra")
      end

      context 'when loading' do
        let(:loaded) { Marshal.load(Marshal.dump(request)) }

        it "includes base_url" do
          expect(loaded.base_url).to eq(request.base_url)
        end

        it "doesn't include #{name}" do
          expect(loaded.instance_variables).to_not include("@hydra")
        end
      end
    end
  end
end
