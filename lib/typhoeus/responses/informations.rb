module Typhoeus
  module Responses
    module Informations
      AVAILABLE_INFORMATIONS = Ethon::Easies::Informations::AVAILABLE_INFORMATIONS.keys+
        [:return_code, :response_body, :response_headers]

      AVAILABLE_INFORMATIONS.each do |name|
        define_method(name) do
          options[name.to_sym]
        end
      end
    end
  end
end

