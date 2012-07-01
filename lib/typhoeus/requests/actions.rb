module Typhoeus
  module Requests # :nodoc:

    # Module containing logic about shortcuts to
    # http methods. Like
    #   Typhoeus.get("www.example.com")
    module Actions
      [:get, :post, :put, :delete, :head, :patch, :options].each do |name|
        define_method(name) do |*args|
          url = args[0]
          options = args.fetch(1, {})
          Request.run(url, options.merge(:method => name))
        end
      end
    end
  end
end
