require 'spec_helper'

describe Typhoeus::Request::Marshal do
  let(:url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(url) }

  describe "#marshal_dump" do
    let(:url) { "http://www.google.com" }

    ['on_complete'].each do |name|
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

          it "includes url" do
            expect(loaded.url).to eq(request.url)
          end

          it "doesn't include #{name}" do
            expect(loaded.instance_variables).to_not include("@#{name}")
          end
        end
      end
    end
  end
end
