module Typhoeus
  class Response

    # This class represents the response header.
    # It can be accessed like a hash.
    #
    # @api private
    class Header < Hash

      # Create a new header.
      #
      # @example Create new header.
      #   Header.new(raw)
      #
      # @param [ String ] raw The raw header.
      def initialize(raw)
        @raw = raw
        @sanitized = {}
        parse
        set_default_proc_on(self, lambda { |h, k| @sanitized[k.to_s.downcase] })
      end

      # Parses the raw header.
      #
      # @example Parse header.
      #   header.parse
      def parse
        case @raw
        when Hash
          raw.each do |k, v|
            process_pair(k, v)
          end
        when String
          raw.lines.each do |header|
            next if header.empty? || header =~ /^HTTP\/1.[01]/
            process_line(header)
          end
        end
      end

      private

      # Processes line and saves the result.
      #
      # @return [ void ]
      def process_line(header)
        key, value = header.split(':', 2).map(&:strip)
        process_pair(key, value)
      end

      # Sets key value pair for self and @sanitized.
      #
      # @return [ void ]
      def process_pair(key, value)
        set_value(key, value, self)
        set_value(key.downcase, value, @sanitized)
      end

      # Sets value for key in specified hash
      #
      # @return [ void ]
      def set_value(key, value, hash)
        if hash.has_key?(key)
          hash[key] = [hash[key]] unless hash[key].is_a? Array
          hash[key].push(value)
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

      # Sets the default proc for the specified hash independent of the Ruby version.
      #
      # @return [ void ]
      def set_default_proc_on(hash, default_proc)
        if hash.respond_to?(:default_proc=)
          hash.default_proc = default_proc
        else
          hash.replace(Hash.new(&default_proc).merge(hash))
        end
      end
    end
  end
end
