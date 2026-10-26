# frozen_string_literal: true

require 'delegate'

module Typhoeus
  class Response

    # This class represents the response header.
    # It can be accessed like a hash.
    # Values can be strings (normal case) or arrays of strings (for duplicates headers)
    #
    # @api private
    class Header < DelegateClass(Hash)

      # Create a new header.
      #
      # @example Create new header.
      #   Header.new(raw)
      #
      # @param [ String ] raw The raw header.
      def initialize(raw)
        super({})
        @raw = raw
        @sanitized = {}
        parse
      end

      def initialize_dup(other)
        super
        copy_delegate(other)
      end
      private :initialize_dup

      def initialize_clone(other, freeze: nil)
        if freeze.nil?
          super(other)
        else
          super(other, freeze: freeze)
        end
        copy_delegate(other)
      end
      private :initialize_clone

      def [](key)
        @sanitized[convert_key(key)]
      end

      def []=(key, value)
        delete_underlying_key(key)
        __getobj__[key] = value
        @sanitized[convert_key(key)] = value
      end
      alias_method :store, :[]=

      def delete(key)
        value = self[key]
        delete_underlying_key(key)
        @sanitized.delete(convert_key(key))
        value
      end

      def clear
        __getobj__.clear
        @sanitized.clear
        self
      end

      def update(other)
        other.each_pair do |key, value|
          value = yield(key, self[key], value) if block_given? && include?(key)
          self[key] = value
        end
        self
      end
      alias_method :merge!, :update

      def replace(other)
        clear
        update(other)
      end

      def delete_if(&block)
        return enum_for(:delete_if) unless block

        super
        rebuild_sanitized
        self
      end

      def keep_if(&block)
        return enum_for(:keep_if) unless block

        super
        rebuild_sanitized
        self
      end

      def select!(&block)
        return enum_for(:select!) unless block

        result = super
        rebuild_sanitized
        result ? self : nil
      end
      alias_method :filter!, :select!

      def reject!(&block)
        return enum_for(:reject!) unless block

        result = super
        rebuild_sanitized
        result ? self : nil
      end

      def shift
        result = super
        rebuild_sanitized
        result
      end

      def compact!
        result = super
        rebuild_sanitized
        result ? self : nil
      end

      def transform_keys!(*args, &block)
        return enum_for(:transform_keys!, *args) if !block && args.empty?

        super
        rebuild_sanitized
        self
      end

      def transform_values!(&block)
        return enum_for(:transform_values!) unless block

        super
        rebuild_sanitized
        self
      end

      def include?(key)
        @sanitized.include?(convert_key(key))
      end
      alias_method :has_key?, :include?
      alias_method :key?, :include?
      alias_method :member?, :include?

      def fetch(key, *extras, &block)
        @sanitized.fetch(convert_key(key), *extras, &block)
      end

      def dig(key, *identifiers)
        @sanitized.dig(convert_key(key), *identifiers)
      end

      def assoc(key)
        @sanitized.assoc(convert_key(key))
      end

      def values_at(*keys)
        keys.map! { |key| convert_key(key) }
        @sanitized.values_at(*keys)
      end

      def fetch_values(*indices, &block)
        indices.map! { |key| convert_key(key) }
        @sanitized.fetch_values(*indices, &block)
      end

      # Parses the raw header.
      #
      # @example Parse header.
      #   header.parse
      def parse
        if raw.respond_to?(:each_pair)
          raw.each_pair do |k, v|
            process_pair(k, v)
          end
        elsif raw.is_a?(String)
          raw.split(/\r?\n(?!\s)/).each do |header|
            header.strip!
            next if header.empty? || header.start_with?( 'HTTP/' )
            process_line(header)
          end
        end
      end

      private

      # Processes line and saves the result.
      #
      # @return [ void ]
      def process_line(header)
        key, value = header.split(':', 2)
        process_pair(key.strip, (value ? value.strip.gsub(/\r?\n\s*/, ' ') : ''))
      end

      # Sets key value pair for self and @sanitized.
      #
      # @return [ void ]
      def process_pair(key, value)
        sanitized_key = convert_key(key)
        set_value(sanitized_key, value, @sanitized)
        self[key] = @sanitized[sanitized_key]
      end

      # Sets value for key in specified hash
      #
      # @return [ void ]
      def set_value(key, value, hash)
        current_value = hash[key]
        if current_value
          if current_value.is_a? Array
            current_value << value
          else
            hash[key] = [current_value, value]
          end
        else
          hash[key] = value
        end
      end

      # Returns the raw header or empty string.
      #
      # @example Return raw header.
      #   header.raw
      #
      # @return [ String ] The raw header.
      def raw
        @raw || ''
      end

      def convert_key(key)
        key.to_s.downcase
      end

      def duplicate_value(value)
        case value
        when Array
          value.map { |nested| duplicate_value(nested) }
        when String
          value.dup
        else
          value
        end
      end

      # DelegateClass copies only the delegated hash itself. Rebuild both
      # hashes so later mutations cannot reach the original header. The
      # sanitized index is built from the copied hash so both stores keep
      # referring to the same values, as they do on the original.
      def copy_delegate(other)
        copy = {}
        other.__getobj__.each do |key, value|
          copy[key] = duplicate_value(value)
        end
        __setobj__(copy)

        @sanitized = {}
        copy.each do |key, value|
          converted = convert_key(key)
          if @sanitized.key?(converted)
            existing = @sanitized[converted]
            existing = [existing] unless existing.is_a?(Array)
            existing.concat(value.is_a?(Array) ? value : [value])
            @sanitized[converted] = existing
          else
            @sanitized[converted] = value
          end
        end
      end

      def delete_underlying_key(key)
        converted = convert_key(key)
        __getobj__.keys.each do |existing_key|
          __getobj__.delete(existing_key) if convert_key(existing_key) == converted
        end
      end

      # Rebuild the case-insensitive index after a Hash mutator that cannot be
      # expressed through #[]=.
      def rebuild_sanitized
        @sanitized = {}
        __getobj__.each do |key, value|
          converted = convert_key(key)
          if @sanitized.key?(converted)
            existing = @sanitized[converted]
            existing = [existing] unless existing.is_a?(Array)
            existing.concat(value.is_a?(Array) ? value : [value])
            @sanitized[converted] = existing
          else
            @sanitized[converted] = value
          end
        end
      end
    end
  end
end
