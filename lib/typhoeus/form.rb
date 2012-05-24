require 'mime/types'

module Typhoeus
  class Form
    attr_accessor :params
    attr_reader :first, :traversal

    def initialize(params = {})
      @params = params
      @first = ::FFI::MemoryPointer.new(:pointer)
      @last = ::FFI::MemoryPointer.new(:pointer)

      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    def self.finalizer(form)
      proc { Curl.formfree(form.first) }
    end

    def traversal
      @traversal ||= Typhoeus::Utils.traverse_params_hash(params)
    end

    def formadd_param(name, contents)
      Curl.formadd(@first, @last,
        :form_option, :copyname, :pointer, name,
        :form_option, :namelength, :long, Utils.bytesize(name),
        :form_option, :copycontents, :pointer, contents,
        :form_option, :contentslength, :long, Utils.bytesize(contents),
        :form_option, :end)
    end
    private :formadd_param

    def formadd_file(name, filename, contenttype, file)
      Curl.formadd(@first, @last,
        :form_option, :copyname, :pointer, name,
        :form_option, :namelength, :long, Utils.bytesize(name),
        :form_option, :file, :string, file,
        :form_option, :filename, :string, filename,
        :form_option, :contenttype, :string, contenttype,
        :form_option, :end)
    end
    private :formadd_file

    def process!
      # add params
      traversal[:params].each { |p| formadd_param(p[0], p[1]) }

      # add files
      traversal[:files].each { |file_args| formadd_file(*file_args) }
    end

    def multipart?
      !traversal[:files].empty?
    end

    def to_s
      Typhoeus::Utils.traversal_to_param_string(traversal, false)
    end
  end
end
