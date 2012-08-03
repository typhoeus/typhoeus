require 'spec_helper'

describe Typhoeus::Requests::Callbacks do
  let(:request) { Typhoeus::Request.new("fubar") }

  after do
    request.on_complete.clear
    Typhoeus.on_complete.clear
  end

  describe "#on_complete" do
    it "responds" do
      expect(request).to respond_to(:on_complete)
    end

    context "when no block given" do
      it "returns @on_complete" do
        expect(request.on_complete).to eq([])
      end
    end

    context "when block given" do
      it "stores" do
        request.on_complete { p 1 }
        expect(request.instance_variable_get(:@on_complete)).to have(1).items
      end
    end

    context "when multiple blocks given" do
      it "stores" do
        request.on_complete { p 1 }
        request.on_complete { p 2 }
        expect(request.instance_variable_get(:@on_complete)).to have(2).items
      end
    end
  end

  describe "#complete" do
    context "when local callback" do
      before do
        request.response = Typhoeus::Response.new
        request.on_complete {|r| expect(r).to be_a(Typhoeus::Response) }
      end

      it "executes blocks and passes response" do
        request.complete
      end
    end

    context "when global callback" do
      before do
        request.response = Typhoeus::Response.new
        Typhoeus.on_complete {|r| expect(r).to be_a(Typhoeus::Response) }
      end

      it "executes blocks and passes response" do
        request.complete
      end
    end

    context "when global and local callbacks" do
      before do
        request.response = Typhoeus::Response.new
        Typhoeus.on_complete {|r| r.instance_variable_set(:@fu, 1) }
        request.on_complete {|r| expect(r.instance_variable_get(:@fu)).to eq(1) }
      end

      it "runs global first" do
        request.complete
      end
    end
  end
end
