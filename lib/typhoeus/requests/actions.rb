module Typhoeus
  module Requests
    module Actions
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
          define_method(name) do |url, params|
            run(url, params.merge(:method => name))
          end
        end
      end
    end
  end
end
