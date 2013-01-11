module Rack
  module Typhoeus
    module Middleware
      class ParamsDecoder
        module Helper

          ##
          # For a cleaner usage in your Rails Controller
          #
          # @example
          #     class ApplicationController
          #       before_filter :decode_typhoeus_arrays
          #       ....
          #
          def decode_typhoeus_arrays
            deep_decode!(params)
          end

          # Recursively decodes Typhoeus encoded arrays in given hash.
          #
          # @param hash [Hash]. This hash will be modified!
          #
          # @author Dwayne Macgowan
          # @version 0.5.4
          #
          # @return [Hash] decoded array
          def deep_decode!(hash)
            return hash unless hash.is_a?(Hash)
            hash.each_pair do |key,value|
              if value.is_a?(Hash)
                deep_decode!(value)
                hash[key] = decode_typhoeus_array(value)
              end
            end
            hash
          end

          def deep_decode(hash)
            deep_decode!(hash.dup)
          end

          private

          # Checks if hash is an Array encoded as a hash.
          # Specifically will check for the hash to have this form: {'0' => v0, '1' => v1, .., 'n' => vN }
          # @param hash [Hash]
          # @return [TrueClass]
          def is_typhoeus_encoded_array?(hash)
            return false if hash.empty?
            hash.keys.map(&:to_i).sort == (0...hash.keys.size).to_a
          end

          # If the hash is an array encoded by typhoeus an array is returned
          # else the self is returned
          #
          # @see im_an_array_typhoeus_encoded?
          # @param hash [Hash]
          #
          # @return [Array/Hash]
          def decode_typhoeus_array(hash)
            if is_typhoeus_encoded_array?(hash)
              Hash[hash.sort].values
            else
              hash
            end
          end
        end
      end
    end
  end
end
