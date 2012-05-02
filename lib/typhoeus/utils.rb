require 'tempfile'

module Typhoeus
  module Utils
    # Taken from Rack::Utils, 1.2.1 to remove Rack dependency.
    def escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/u) {
        '%'+$1.unpack('H2'*bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end
    module_function :escape

    # Params are NOT escaped.
    def traverse_params_hash(hash, result = nil, current_key = nil)
      result = ParamProcessor.traverse_params_hash hash, result, current_key
    end
    module_function :traverse_params_hash

    def traversal_to_param_string(traversal, escape = true)
      traversal[:params].collect { |param|
        escape ? "#{Typhoeus::Utils.escape(param[0])}=#{Typhoeus::Utils.escape(param[1])}" : "#{param[0]}=#{param[1]}"
      }.join('&')
    end
    module_function :traversal_to_param_string

    # Return the bytesize of String; uses String#size under Ruby 1.8 and
    # String#bytesize under 1.9.
    if ''.respond_to?(:bytesize)
      def bytesize(string)
        string.bytesize
      end
    else
      def bytesize(string)
        string.size
      end
    end
    module_function :bytesize

    private

    def process_value(current_value, options)
      result = options[:result]
      new_key = options[:new_key]

      case current_value
      when Hash
        traverse_params_hash(current_value, result, new_key)
      when Array
        current_value.each do |v|
          result[:params] << [new_key, v.to_s]
        end
      when File, Tempfile
        filename = File.basename(current_value.path)
        types = MIME::Types.type_for(filename)
        result[:files] << [
          new_key,
          filename,
          types.empty? ? 'application/octet-stream' : types[0].to_s,
          File.expand_path(current_value.path)
        ]
      else
        result[:params] << [new_key, current_value.to_s]
      end
    end
    module_function :process_value
  end
end
