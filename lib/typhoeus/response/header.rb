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
          unless header =~ /^HTTP\/1.[01]/
            parts = header.split(':', 2)
            unless parts.empty?
              parts.map(&:strip!)
              if self.has_key?(parts[0])
                self[parts[0]] = [self[parts[0]]] unless self[parts[0]].kind_of? Array
                self[parts[0]] << parts[1]
              else
                self[parts[0]] = parts[1]
              end
            end
          end
        end
      end

      private

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
