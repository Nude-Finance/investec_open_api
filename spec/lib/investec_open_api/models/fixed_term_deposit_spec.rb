require "spec_helper"
require "investec_open_api/models/fixed_term_deposit"

RSpec.describe InvestecOpenApi::Models::FixedTermDeposit do
  describe ".from_api" do
    context "with valid attributes" do
      it "returns a new instance of InvestecOpenApi::Models::FixedTermDeposit with attributes" do
        model_instance = InvestecOpenApi::Models::FixedTermDeposit.from_api({
          "id" => "ftd123456",
          "startDate" => "2024-01-01",
          "endDate" => "2024-07-01",
          "productType" => "32 Day Notice",
          "interestRatePercent" => 5.75,
          "currency" => "ZAR",
          "amount" => 50000.00,
          "status" => "ACTIVE",
          "externalReference" => "my-savings-001"
        })

        expect(model_instance.id).to eq "ftd123456"
        expect(model_instance.start_date).to eq Date.parse("2024-01-01")
        expect(model_instance.end_date).to eq Date.parse("2024-07-01")
        expect(model_instance.product_type).to eq "32 Day Notice"
        expect(model_instance.interest_rate_percent).to eq 5.75
        expect(model_instance.amount.class).to eq Money
        expect(model_instance.amount.to_f).to eq 50000.00
        expect(model_instance.amount.format).to eq "R50000.00"
        expect(model_instance.status).to eq "ACTIVE"
        expect(model_instance.external_reference).to eq "my-savings-001"
        expect(model_instance.currency).to eq "ZAR"
      end
    end

    context "with valid and invalid attributes" do
      it "returns a new instance of InvestecOpenApi::Models::FixedTermDeposit with only valid attributes" do
        model_instance = InvestecOpenApi::Models::FixedTermDeposit.from_api({
          "id" => "ftd123456",
          "startDate" => "2024-01-01",
          "amount" => 50000.00,
          "status" => "ACTIVE",
          "invalidAttribute" => "should be ignored"
        })

        expect(model_instance.id).to eq "ftd123456"
        expect(model_instance.start_date).to eq Date.parse("2024-01-01")
        expect(model_instance.amount.class).to eq Money
        expect(model_instance.status).to eq "ACTIVE"

        expect { model_instance.invalid_attribute }.to raise_error(NoMethodError)
      end
    end
  end
end 