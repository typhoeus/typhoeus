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

      # Processes a single value
      #
      #  @param [Object] value - value being processed
      #  @param [Hash] options - options for processing
      #      :result - method side-effect, value will be added to result[:params]. So actually it must be an array.
      #      :new_key - key for processing. value will be added to result[:params] with that key.
      def process_value(value, options = {})
        raise ArgumentError, "options should be an instance of Hash, but was #{options.class}" unless options.is_a?(Hash)

        result = options[:result]
        new_key = options[:new_key]

        case value
        when Hash
          traverse_params_hash(value, result, new_key)
        when Array
          value.each do |v|
            result[:params] << [new_key, v.to_s]
          end
        when File, Tempfile
          filename = File.basename(value.path)
          types = MIME::Types.type_for(filename)
          result[:files] << [
            new_key,
            filename,
            types.empty? ? 'application/octet-stream' : types[0].to_s,
            File.expand_path(value.path)
          ]
        else
          result[:params] << [new_key, value.to_s]
        end
      end

    end # class << self
  end # class ParamProcessor
end # module Typhoeus
