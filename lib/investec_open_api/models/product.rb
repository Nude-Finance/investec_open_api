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
        
        # Check start_date (if exists)
        start_check = start_date.nil? || today >= start_date
        
        # Check end_date (if exists)
        end_check = end_date.nil? || today <= end_date
        
        # Product is active if both conditions are true
        start_check && end_check
      end
    end
  end
end 