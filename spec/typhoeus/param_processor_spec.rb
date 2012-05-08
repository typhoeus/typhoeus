require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Typhoeus
  describe ParamProcessor do
    describe '.process_value' do
      let(:result) { {:files => [], :params => []} }
      let(:params) { result[:params] }

      context 'simple values' do
        it 'should write a key-value pair to result[:params]' do
          ParamProcessor.process_value 'value', :result => result, :new_key => 'key'
          params.should == [['key', 'value']]
        end

        it "should not overwrite what's already in result[:params]" do
          result[:params] << ['old', '1']
          ParamProcessor.process_value 2, :result => result, :new_key => 'new'
          params.should == [['old', '1'], ['new', '2']]
        end
      end

      context 'arrays' do
        it 'should write a value for each array item' do
          ParamProcessor.process_value [1, 'two', :'3'], :result => result, :new_key => 'array'
          params.should == [['array', '1'], ['array', 'two'], ['array', '3']]
        end
      end

      context 'files' do
        let(:files) { result[:files] }

        context 'regular files' do
          let(:temp_directory) { Dir.mktmpdir }
          let(:file) do
            file = File.new File.join(temp_directory, 'testfile.txt'), 'w'
            file.puts 'some text'
            file
          end

          after :each do
            file.close
            FileUtils.remove_entry_secure temp_directory if temp_directory
          end

          it 'should write file information to result[:files]' do
            ParamProcessor.process_value file, :result => result, :new_key => 'file'
            path = file.path
            files.should == [['file', File.basename(path), MIME::Types.type_for(path).first, path]]
          end
        end

        context 'temporary files' do
          let(:tempfile) do
            tempfile = Tempfile.new(['foo', '.txt'])
            tempfile.puts 'some text'
            tempfile
          end

          after :each do
            tempfile.close
            tempfile.unlink
          end

          it 'should write file information to result[:files]' do
            ParamProcessor.process_value tempfile, :result => result, :new_key => 'tempfile'
            path = tempfile.path
            files.should == [['tempfile', File.basename(path), MIME::Types.type_for(path).first, path]]
          end
        end
      end

      context 'hashes' do
        it 'should nest values under the key' do
          ParamProcessor.process_value({:one => 1, 'two' => 2}, :result => result, :new_key => 'key')
          params.should == [['key[one]', '1'], ['key[two]', '2']]
        end

        it 'should nest values recursively' do
          ParamProcessor.process_value({:array => [1, 2], :hash => {:key => 'value'}}, :result => result, :new_key => 'outer_key')
          params.should == [['outer_key[array]', '1'], ['outer_key[array]', '2'], ['outer_key[hash][key]', 'value']]
        end
      end
    end
  end
end
