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
          "startDate" => "2024-01-01",
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
  
  describe "#active?" do
    let(:today) { Date.today }
    
    context "when the product is currently active" do
      it "returns true when today is within the start and end dates" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => (today - 10).to_s,
          "endDate" => (today + 10).to_s
        })
        
        expect(product.active?).to be true
      end
      
      it "returns true when today is equal to the start date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => today.to_s,
          "endDate" => (today + 10).to_s
        })
        
        expect(product.active?).to be true
      end
      
      it "returns true when today is equal to the end date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => (today - 10).to_s,
          "endDate" => today.to_s
        })
        
        expect(product.active?).to be true
      end
    end
    
    context "when the product has no start date" do
      it "returns true if today is before or equal to the end date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "endDate" => (today + 10).to_s
        })
        
        expect(product.active?).to be true
      end
      
      it "returns false if today is after the end date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "endDate" => (today - 1).to_s
        })
        
        expect(product.active?).to be false
      end
    end
    
    context "when the product has no end date" do
      it "returns false if today is before the start date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => (today + 1).to_s
        })
        
        expect(product.active?).to be false
      end
    end
    
    context "when the product has neither start nor end date" do
      it "returns true (always active)" do
        product = InvestecOpenApi::Models::Product.from_api({})
        
        expect(product.active?).to be true
      end
    end
    
    context "when the product is not active" do
      it "returns false when today is before the start date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => (today + 1).to_s,
          "endDate" => (today + 10).to_s
        })
        
        expect(product.active?).to be false
      end
      
      it "returns false when today is after the end date" do
        product = InvestecOpenApi::Models::Product.from_api({
          "startDate" => (today - 10).to_s,
          "endDate" => (today - 1).to_s
        })
        
        expect(product.active?).to be false
      end
    end
  end
end 