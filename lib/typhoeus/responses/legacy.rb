module Typhoeus
  module Responses
    module Legacy
      MAPPING = {
        :body => :response_body,
        :headers => :response_headers,
        :code => :response_code,
        :curl_return_code => :return_code,
        :time => :total_time,
        :app_connect_time => :appconnect_time,
        :start_transfer_time => :starttransfer_time,
        :name_lookup_time => :namelookup_time
      }

      MAPPING.each do |old, new|
        define_method(old) do
          options[new]
        end
      end
    end
  end
end
