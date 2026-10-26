# frozen_string_literal: true

module Typhoeus
  module Errors

    # Raised for options Typhoeus knows about but Ethon does not accept.
    #
    # It stays compatible with Ethon's InvalidOption while carrying the
    # replacement or removal hint that Typhoeus adds.
    class InvalidOption < Ethon::Errors::InvalidOption
      def initialize(option, help = nil)
        super(option)
        @help = help
      end

      def message
        "#{super}#{@help}"
      end
    end
  end
end
