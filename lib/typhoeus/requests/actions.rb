module Typhoeus
  module Requests
    module Actions
      [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
        define_method(name) do |url, params|
          Request.run(url, params.merge(:method => name))
        end
      end
    end
  end
end
