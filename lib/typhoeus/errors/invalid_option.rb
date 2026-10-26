# frozen_string_literal: true

module Typhoeus
  module Errors

    # Raised for options Typhoeus knows about but Ethon does not accept.
    #
    # It stays compatible with Ethon's InvalidOption while carrying the
    # replacement or removal hint that Typhoeus adds.
    class InvalidOption < Ethon::Errors::InvalidOption
      def initialize(option, help = nil)
        @help = help
        super(option)
      end

      # Exception#message calls #to_s, so the hint is included everywhere the
      # error is rendered and not only when #message is called explicitly.
      def to_s
        "#{super}#{@help}"
      end
    end
  end
end
