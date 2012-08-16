require 'spec_helper'

describe Typhoeus::Hydra::Runnable do
  let(:url) { "localhost:3001" }
  let(:options) { {} }
  let(:hydra) { Typhoeus::Hydra.new(options) }

  describe "#run" do
    before do
      requests.each { |r| hydra.queue r }
    end

    context "when no request queued" do
      let(:requests) { [] }

      it "does nothing" do
        hydra.multi.should_receive(:perform)
        hydra.run
      end
    end

    context "when request queued" do
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:requests) { [first] }

      it "runs multi#perform" do
        hydra.multi.should_receive(:perform)
        hydra.run
      end

      it "sends" do
        hydra.run
        expect(first.response).to be
      end
    end

    context "when three request queued" do
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:second) { Typhoeus::Request.new("localhost:3001/second") }
      let(:third) { Typhoeus::Request.new("localhost:3001/third") }
      let(:requests) { [first, second, third] }

      it "runs multi#perform" do
        hydra.multi.should_receive(:perform)
        hydra.run
      end

      it "sends first" do
        hydra.run
        expect(first.response).to be
      end

      it "sends second" do
        hydra.run
        expect(second.response).to be
      end

      it "sends third" do
        hydra.run
        expect(third.response).to be
      end

      it "sends first first" do
        first.on_complete do
          expect(second.response).to be_nil
          expect(third.response).to be_nil
        end
      end

      it "sends second second" do
        first.on_complete do
          expect(first.response).to be
          expect(third.response).to be_nil
        end
      end

      it "sends thirds last" do
        first.on_complete do
          expect(second.response).to be
          expect(third.response).to be
        end
      end
    end

    context "when really queued request" do
      let(:options) { {:max_concurrency => 1} }
      let(:first) { Typhoeus::Request.new("localhost:3001/first") }
      let(:second) { Typhoeus::Request.new("localhost:3001/second") }
      let(:third) { Typhoeus::Request.new("localhost:3001/third") }
      let(:requests) { [first, second, third] }

      it "sends first" do
        hydra.run
        expect(first.response).to be
      end

      it "sends second" do
        hydra.run
        expect(second.response).to be
      end

      it "sends third" do
        hydra.run
        expect(third.response).to be
      end
    end
  end
end
