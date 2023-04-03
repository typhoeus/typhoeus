require 'spec_helper'

describe Typhoeus::Request::Marshal do
  let(:base_url) { 'localhost:3001' }
  let(:request) { Typhoeus::Request.new(base_url) }

  describe '#marshal_dump' do
    %w[on_complete on_success on_failure on_progress].each do |name|
      context "when #{name} handler" do
        before { request.instance_variable_set("@#{name}", proc {}) }

        it "doesn't include @#{name}" do
          expect(request.send(:marshal_dump).map(&:first)).not_to include("@#{name}")
        end

        it "doesn't raise when dumped" do
          expect { Marshal.dump(request) }.not_to raise_error
        end

        context 'when loading' do
          let(:loaded) { Marshal.load(Marshal.dump(request)) }

          it 'includes base_url' do
            expect(loaded.base_url).to eq(request.base_url)
          end

          it "doesn't include #{name}" do
            expect(loaded.instance_variables).not_to include("@#{name}")
          end
        end
      end
    end

    context 'when run through hydra' do
      let(:options) { {} }
      let(:hydra) { Typhoeus::Hydra.new(options) }

      before do
        hydra.queue(request)
        hydra.run
      end

      it "doesn't include @hydra" do
        expect(request.send(:marshal_dump).map(&:first)).not_to include('@hydra')
      end

      context 'when loading' do
        let(:loaded) { Marshal.load(Marshal.dump(request)) }

        it 'includes base_url' do
          expect(loaded.base_url).to eq(request.base_url)
        end

        it "doesn't include #{name}" do
          expect(loaded.instance_variables).not_to include('@hydra')
        end
      end
    end
  end
end
