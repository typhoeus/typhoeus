# frozen_string_literal: true

module Rack
  module Typhoeus
    module Middleware
      class ParamsDecoder
        module Helper

          # Recursively decodes Typhoeus encoded arrays in given Hash.
          #
          # @example Use directly in a Rails controller.
          #    class ApplicationController
          #       before_filter :decode_typhoeus_arrays
          #    end
          #
          # @author Dwayne Macgowan
          #
          def decode_typhoeus_arrays
            decode!(params)
          end

          # Recursively decodes Typhoeus encoded arrays in given Hash.
          #
          # @param hash [Hash]. This Hash will be modified!
          #
          # @return [Hash] Hash with properly decoded nested arrays.
          def decode!(hash)
            return hash unless hash.respond_to?(:each_pair) || hash.is_a?(Array)

            if hash.is_a?(Array)
              hash.map! { |value| decode_value(value) }
            else
              hash.each_pair do |key, value|
                hash[key] = decode_value(value)
              end
            end
            hash
          end

          def decode(hash)
            decode!(deep_dup(hash))
          end

          private

          # Decode one value, keeping plain values untouched.
          #
          # @param [ Object ] value The value to decode.
          #
          # @return [ Object ] The decoded value.
          def decode_value(value)
            if value.respond_to?(:each_pair)
              decoded = decode!(value)
              convert(hash_like_to_hash(decoded))
            elsif value.is_a?(Array)
              decode!(value)
            else
              value
            end
          end

          # Copy nested hashes and arrays so decoding cannot mutate the
          # caller's params.
          #
          # @param [ Object ] value The value to copy.
          #
          # @return [ Object ] The copied value.
          def deep_dup(value)
            if value.respond_to?(:each_pair)
              copy = {}
              value.each_pair { |key, nested| copy[key] = deep_dup(nested) }
              copy
            elsif value.is_a?(Array)
              value.map { |nested| deep_dup(nested) }
            else
              value
            end
          end

          # Copy a hash-like object without calling conversion methods such as
          # Parameters#to_h, which raise for unpermitted Rails parameters.
          #
          # @param [ Object ] value The value to copy.
          #
          # @return [ Hash ] The copied hash.
          def hash_like_to_hash(value)
            return value if value.is_a?(Hash)

            copy = {}
            value.each_pair { |key, nested| copy[key] = nested }
            copy
          end

          # Checks if Hash is an Array encoded as a Hash.
          # Specifically will check for the Hash to have this
          # form: {'0' => v0, '1' => v1, .., 'n' => vN }
          #
          # @param hash [Hash]
          #
          # @return [Boolean] True if its a encoded Array, else false.
          def encoded?(hash)
            return false if hash.empty?

            keys = hash.keys.map(&:to_s)
            return keys.first == "0" if keys.size == 1

            keys.all? { |key| key == key.to_i.to_s } &&
              keys.map(&:to_i).sort == (0...keys.size).to_a
          end

          # If the Hash is an array encoded by typhoeus an array is returned
          # else the self is returned
          #
          # @param hash [Hash] The Hash to convert into an Array.
          #
          # @return [Arraya/Hash]
          def convert(hash)
            if encoded?(hash)
              hash.sort { |a, b| a[0].to_s.to_i <=> b[0].to_s.to_i }.map { |_, value| value }
            else
              hash
            end
          end
        end
      end
    end
  end
end
