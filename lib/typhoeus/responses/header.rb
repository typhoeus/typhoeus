module Typhoeus
  module Responses
    class Header < Hash
      attr_accessor :raw_header

      def initialize(raw_header)
        @raw_header = raw_header
        parse
      end

      def raw_header
        @raw_header ||= ''
      end

      def parse
        raw_header.lines.each do |header|
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
    end
  end
end
