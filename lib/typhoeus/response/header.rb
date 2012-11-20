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
        parse
      end

      # Parses the raw header.
      #
      # @example Parse header.
      #   header.parse
      def parse
        raw.lines.each do |header|
          next if header.empty? || header =~ /^HTTP\/1.[01]/
          process_line(header)
        end
      end

      def [](key)
        self.each do |k, v|
          return v if k.downcase == key.downcase
        end
      end

      private

      # Processes line and saves the result.
      #
      # @return [ void ]
      def process_line(header)
        key, value = header.split(':', 2).map(&:strip)
        if self.has_key?(key)
          self[key] = [self[key]] unless self[key].is_a? Array
          self[key].push(value)
        else
          self[key] = value
        end
      end

      # Returns the raw header or empty string.
      #
      # @example Return raw header.
      #   header.raw
      #
      # @return [ String ] The raw header.
      def raw
        @raw ||= ''
      end
    end
  end
end
