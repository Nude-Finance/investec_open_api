require "money"

module InvestecOpenApi
  module Models
    class Product < Base
      attr_reader :id, 
                  :name, 
                  :currency, 
                  :type, 
                  :aer, 
                  :gross_rate, 
                  :description, 
                  :term, 
                  :start_date, 
                  :end_date

      def self.from_api(params = {})
        # Handle the lowercase 'startdate' in API response
        rewrite_param_key(params, "startdate", "start_date")
        rewrite_param_key(params, "endDate", "end_date")
        rewrite_param_key(params, "grossRate", "gross_rate")
        
        # Convert date strings to Date objects
        convert_param_value_to_date(params, "start_date")
        convert_param_value_to_date(params, "end_date")
        
        new params
      end
    end
  end
end 