module Typhoeus
  class Request

    # This class provides utility methods to Typhoeus::Request to deal with
    # sorting and assembling URL parameters
    #
    # @example None
    #    
    module Util
      extend self

      # URI Encodes a string
      #
      # @return  [ String ]
      def escape(s)
        URI.encode_www_form_component(s.to_s)
      end

      # Creates a query string out of a parameter hash
      #
      # @return  [ String ]
      def build_query(params)
        params.map {|k,v|
          if v.class == Array
            build_query(v.map{|x|[k, x]})
          else
            "#{escape(k)}=" + (v.nil? ? '' : escape(v))
          end
        }.join("&")
      end

      # Sorts an array of key value pairs
      #
      # @return  [ Array ] Sorted array of key value pairs.     
      def sort_params(params=[])
        params.sort{|a,b| a.first.to_s <=> b.first.to_s}
      end

      # Explodes a query string in to an array of key value pairs
      #
      # @return  [ Array ] Array of key value pairs.           
      def explode_query_string(query_string)
        (query_string||'').split('&').map{|a| a.split('=')}
      end

      # Combines a optional  param string taken from the base url, with the params specified in options.
      #
      # @return  [ Array ] Array of key value pairs.                 
      def param_pairs(base_url_params)
        Array.new.tap do |arr|          
          arr.concat explode_query_string(base_url_params) if base_url_params
          arr.concat options[:params].to_a if options[:params]
        end
      end   
      
      # Returns the base_url + parameters, taking in to account paramters already attached to the base_url, 
      # as well as alphabetizing the parameters so that the URL is consistently returned
      #
      # @return [ String ] Full URL with sorted Parameters
      def url
        url = base_url
        # Strip off trailing ampersands to make the addition of parameters cleaner.
        url.chomp!('&')
        (host,param_string) = url.split('?',2)      
        params = build_query(sort_params(param_pairs(param_string)))
        "#{host}?#{params}"
      end
    end
  end
end