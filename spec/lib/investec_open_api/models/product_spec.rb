require "spec_helper"
require "investec_open_api/models/product"

RSpec.describe InvestecOpenApi::Models::Product do
  describe ".from_api" do
    context "with valid attributes" do
      it "returns a new instance of InvestecOpenApi::Models::Product with attributes" do
        model_instance = InvestecOpenApi::Models::Product.from_api({
          "id" => "32DayNotice",
          "name" => "32 Day Notice Account",
          "currency" => "GBP",
          "type" => "NoticeSavings",
          "aer" => 4.25,
          "grossRate" => 4.17,
          "description" => "A 32 day notice account",
          "term" => "32 days",
          "startdate" => "2024-01-01",
          "endDate" => "2024-12-31"
        })

        expect(model_instance.id).to eq "32DayNotice"
        expect(model_instance.name).to eq "32 Day Notice Account"
        expect(model_instance.currency).to eq "GBP"
        expect(model_instance.type).to eq "NoticeSavings"
        expect(model_instance.aer).to eq 4.25
        expect(model_instance.gross_rate).to eq 4.17
        expect(model_instance.description).to eq "A 32 day notice account"
        expect(model_instance.term).to eq "32 days"
        expect(model_instance.start_date).to eq Date.parse("2024-01-01")
        expect(model_instance.end_date).to eq Date.parse("2024-12-31")
      end
    end
  end
end 