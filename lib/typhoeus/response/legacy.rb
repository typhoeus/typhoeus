module Typhoeus
  class Response # :nodoc:

    # This module contains logic for providing the
    # old accessors.
    module Legacy

      # The legacy mapping.
      MAPPING = {
        :body => :response_body,
        :code => :response_code,
        :curl_return_code => :return_code,
        :time => :total_time,
        :app_connect_time => :appconnect_time,
        :start_transfer_time => :starttransfer_time,
        :name_lookup_time => :namelookup_time,
        :headers_hash => :header
      }

      MAPPING.each do |old, new|
        define_method(old) do
          options[new] || options[old]
        end
      end
    end
  end
end
