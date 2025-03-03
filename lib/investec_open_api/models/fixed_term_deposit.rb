require "money"

module InvestecOpenApi
  module Models
    class FixedTermDeposit < Base
      attr_reader :id, :start_date, :end_date, :product_type, :interest_rate_percent, :amount, :status, :external_reference, :currency
      def self.from_api(params, currency = "ZAR")
        params["currency"] = currency unless params["currency"]
        
        convert_param_value_to_money(params, "amount")
        
        # First, rename the keys
        rewrite_param_key(params, "startDate", "start_date")
        rewrite_param_key(params, "endDate", "end_date")
        rewrite_param_key(params, "productType", "product_type")
        rewrite_param_key(params, "interestRatePercent", "interest_rate_percent")
        rewrite_param_key(params, "externalReference", "external_reference")
        
        # Then convert the renamed keys to dates
        convert_param_value_to_date(params, "start_date")
        convert_param_value_to_date(params, "end_date")
        
        new params
      end
    end
  end
end

