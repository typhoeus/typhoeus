require 'mime/types'

module Typhoeus

  # Helper class for building multipart formsposts.
  #
  class Form
    attr_accessor :params
    attr_reader :first, :traversal

    def initialize(params = {})
      raise ArgumentError, "params should be an instance of Hash, but was #{params.class}" unless params.is_a?(Hash)

      @params = params
      @first = ::FFI::MemoryPointer.new(:pointer)
      @last = ::FFI::MemoryPointer.new(:pointer)

      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    #
    # API
    #

    # Wrapper over curl_formfree. Frees a multipart formpost.
    def self.finalizer(form)
      proc { Curl.formfree(form.first) }
    end

    def traversal
      @traversal ||= Typhoeus::Utils.traverse_params_hash(params)
    end

    def process!
      # add params
      traversal[:params].each { |p| formadd_param(p[0], p[1]) }

      # add files
      traversal[:files].each { |file_args| formadd_file(*file_args) }
    end

    # Wether or not the form is multipart
    #
    def multipart?
      !traversal[:files].empty?
    end

    def to_s
      Typhoeus::Utils.traversal_to_param_string(traversal, false)
    end

    #
    # Implementation
    #

    private

    # Wrapper over curl_formadd. Each invoke adds one
    def formadd_param(name, contents)
      Curl.formadd(@first, @last,
        :form_option, :copyname, :pointer, name,
        :form_option, :namelength, :long, Utils.bytesize(name),
        :form_option, :copycontents, :pointer, contents,
        :form_option, :contentslength, :long, Utils.bytesize(contents),
        :form_option, :end)
    end

    # Wrapper over curl_formadd, specifically for adding files.
    #
    def formadd_file(name, filename, contenttype, file)
      Curl.formadd(@first, @last,
        :form_option, :copyname, :pointer, name,
        :form_option, :namelength, :long, Utils.bytesize(name),
        :form_option, :file, :string, file,
        :form_option, :filename, :string, filename,
        :form_option, :contenttype, :string, contenttype,
        :form_option, :end)
    end

  end
end
