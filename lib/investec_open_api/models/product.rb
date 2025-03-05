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
        rewrite_param_key(params, "startDate", "start_date")
        rewrite_param_key(params, "endDate", "end_date")
        rewrite_param_key(params, "grossRate", "gross_rate")
        
        # Convert date strings to Date objects
        convert_param_value_to_date(params, "start_date")
        convert_param_value_to_date(params, "end_date")
        
        new params
      end
      
      # Determines if the product is currently active based on its date range
      # @return [Boolean] true if today is within the product's start and end dates
      def active?
        today = Date.today
        
        return false if start_date.nil? || end_date.nil?
        
        start_ok = today >= start_date
        
        end_ok = today <= end_date
        
        start_ok && end_ok
      end
    end
  end
end 