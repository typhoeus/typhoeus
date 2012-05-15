require 'tempfile'

module Typhoeus
  class ParamProcessor
    class << self
      def traverse_params_hash(hash, result = nil, current_key = nil)
        result ||= { :files => [], :params => [] }

        hash.keys.sort { |a, b| a.to_s <=> b.to_s }.collect do |key|
          new_key = (current_key ? "#{current_key}[#{key}]" : key).to_s
          current_value = hash[key]
          process_value current_value, :result => result, :new_key => new_key
        end
        result
      end

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
    end
  end
end
