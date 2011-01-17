require 'mime/types'

module Typhoeus
  class Form
    attr_accessor :params

    def initialize(params = {})
      @params = params
    end

    def process!
      params.each do |key, value|
        case value
          when Hash
            value.keys.each {|sub_key| formadd_param("#{key}[#{sub_key}]", value[sub_key].to_s)}
          when Array
            value.each {|v| formadd_param(key.to_s, v.to_s)}
          when File
            filename = File.basename(value.path)
            types = MIME::Types.type_for(filename)
            return formadd_file(
              key.to_s,
              filename,
              types.empty? ? 'application/octet-stream' : types[0].to_s,
              File.expand_path(value.path)
            )
          else
            return formadd_param(key.to_s, value.to_s)
        end
      end
    end

    def to_s
      params.keys.collect do |k|
        value = params[k]
        if value.is_a? Hash
          value.keys.collect {|sk| Typhoeus::Utils.escape("#{k}[#{sk}]") + "=" + Typhoeus::Utils.escape(value[sk].to_s)}
        elsif value.is_a? Array
          key = Typhoeus::Utils.escape(k.to_s)
          value.collect { |v| "#{key}=#{Typhoeus::Utils.escape(v.to_s)}" }.join('&')
        else
          "#{Typhoeus::Utils.escape(k.to_s)}=#{Typhoeus::Utils.escape(params[k].to_s)}"
        end
      end.flatten.join("&")
    end
  end
end