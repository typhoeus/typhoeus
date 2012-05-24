module Typhoeus
  module EasyFu
    module FFIHelper
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def finalizer(easy)
          proc {
            Curl.slist_free_all(easy.header_list) if easy.header_list
            Curl.easy_cleanup(easy.handle)
          }
        end
      end

      def handle
        @handle ||= Curl.easy_init
      end

      def body_write_callback
        @body_write_callback ||= proc {|stream, size, num, object|
          response_body << stream.read_string(size * num)
          size * num
        }
      end

      def header_write_callback
        @header_write_callback ||= proc {|stream, size, num, object|
          response_header << stream.read_string(size * num)
          size * num
        }
      end

      def read_callback
        @read_callback ||= proc {|stream, size, num, object|
          size = size * num
          left = Utils.bytesize(@request_body) - @request_body_read
          size = left if size > left
          if size > 0
            stream.write_string(Utils.byteslice(@request_body, @request_body_read, size), size)
            @request_body_read += size
          end
          size
        }
      end

      def string_ptr
        @string_ptr ||= ::FFI::MemoryPointer.new(:pointer)
      end

      def long_ptr
        @long_ptr ||= ::FFI::MemoryPointer.new(:long)
      end

      def double_ptr
        @double_ptr ||= ::FFI::MemoryPointer.new(:double)
      end
    end
  end
end
