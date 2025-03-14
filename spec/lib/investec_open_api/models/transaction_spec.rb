require "spec_helper"
require "investec_open_api/models/transaction"

RSpec.describe InvestecOpenApi::Models::Transaction do
  describe "#from_api" do
    context "with valid attributes" do
      it "returns a new instance of InvestecOpenApi::Models::Transaction with attributes" do
        account_id = "123456789"
        posting_date = "2020-07-14"
        posted_order = 4
        uuid = "#{account_id.slice(0,5)}#{posting_date.gsub(/-/, "")}#{posted_order.to_s.rjust(7, "0")}"
        model_instance = InvestecOpenApi::Models::Transaction.from_api({
          "accountId" => account_id,
          "type" => "DEBIT",
          "status" => "POSTED",
          "cardNumber" => "400000xxxxxx0001",
          "amount" => 50000.32,
          "description" => "Zapper COFFEE SHOP ZA",
          "transactionDate" => "2020-07-13",
          "postedOrder" => posted_order,
          "postingDate" => posting_date,
          "valueDate" => "2020-07-15",
          "actionDate" => "2020-07-21",
          "runningBalance" => 100000.64,
          "transactionType" => "CardPurchases",
          "uuid" => uuid
        })

        expect(model_instance.account_id).to eq "123456789"
        expect(model_instance.uuid).to eq("12345202007140000004")
        expect(model_instance.type).to eq "DEBIT"
        expect(model_instance.status).to eq "POSTED"
        expect(model_instance.card_number).to eq "400000xxxxxx0001"
        expect(model_instance.amount.class).to eq Money
        expect(model_instance.amount.to_f).to eq -50000.32
        expect(model_instance.amount.format).to eq "R-50000.32"
        expect(model_instance.description).to eq "Zapper COFFEE SHOP ZA"
        expect(model_instance.date).to eq Date.parse("2020-07-13")
        expect(model_instance.posting_date).to eq Date.parse("2020-07-14")
        expect(model_instance.posted_order).to eq 4
        expect(model_instance.value_date).to eq Date.parse("2020-07-15")
        expect(model_instance.action_date).to eq Date.parse("2020-07-21")
        expect(model_instance.running_balance.class).to eq Money
        expect(model_instance.running_balance.to_f).to eq 100000.64
        expect(model_instance.running_balance.format).to eq "R100000.64"
        expect(model_instance.transaction_type).to eq "CardPurchases"
      end
    end

    context "with valid and invalid attributes" do
      it "returns a new instance of InvestecOpenApi::Models::Transaction with only valid attributes" do
        model_instance = InvestecOpenApi::Models::Transaction.from_api({
          "accountId" => "12345",
          "type" => "DEBIT",
          "bankAccountNumber" => "67890",
          "description" => "Zapper COFFEE SHOP ZA",
          "date" => "2020-07-13",
          "amount" => 50000.32
        })

        expect(model_instance.account_id).to eq "12345"
        expect(model_instance.type).to eq "DEBIT"

        expect { model_instance.bank_account_number }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#id" do
    it "creates a unique ID based on the amount, description and date" do
      model_instance = InvestecOpenApi::Models::Transaction.from_api({
        "accountId" => "12345",
        "type" => "DEBIT",
        "status" => "POSTED",
        "cardNumber" => "400000xxxxxx0001",
        "amount" => 50000,
        "description" => "COFFEE ORDER",
        "transactionDate" => "2020-07-13",
        "postedOrder" => 1,
        "postingDate" => "2020-07-14",
        "valueDate" => "2020-07-15",
        "actionDate" => "2020-07-21"
      })

      expect(model_instance.id).to eq "-50000-COFFEE ORDER-2020-07-13"
    end
  end
end
