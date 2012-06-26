module Typhoeus
  module Requests
    module Actions
      [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
        define_method(name) do |*args|
          url = args[0]
          options = args[1] || {}
          Request.run(url, options.merge(:method => name))
        end
      end
    end
  end
end
