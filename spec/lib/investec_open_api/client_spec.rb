require "spec_helper"
require "investec_open_api/client"
require "investec_open_api/models/account"
require "investec_open_api/models/transaction"
require "investec_open_api/models/transfer"

RSpec.describe InvestecOpenApi::Client do
  let(:client) { InvestecOpenApi::Client.new }
  let(:api_url) { 'https://openapi.investec.com/' }
  let(:headers) do
    {
      "Accept" => "application/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization" => "Bearer 123",
      "User-Agent" => "Faraday v2.9.0"
    }
  end

  before do
    InvestecOpenApi.config.api_key = "TESTKEY"
    InvestecOpenApi.config.client_id = "Test"
    InvestecOpenApi.config.client_secret = "Secret"
    InvestecOpenApi.config.base_url = api_url

    stub_request(:post, "#{api_url}identity/v2/oauth2/token")
      .with(
        body: { "grant_type" => "client_credentials" },
        headers: headers.merge({
          'Accept' => '*/*',
          'Authorization' => 'Basic VGVzdDpTZWNyZXQ=',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'X-Api-Key' => 'TESTKEY'
        }))
      .to_return(status: 200, body: {
        "access_token": "123",
        "token_type": "Bearer",
        "expires_in": 1799,
        "scope": "accounts"
      }.to_json, headers: {})
  end

  describe "#accounts" do
    before do
      stub_request(:get, "#{api_url}za/pb/v1/accounts")
        .with(
          body: "",
          headers: headers
        )
        .to_return(
          body: {
            data: {
              accounts: [
                {
                  "accountId" => "12345",
                  "accountNumber" => "67890",
                  "accountName" => "Test User",
                  "referenceName" => "My Private Investec Bank Account",
                  "productName" => "Private Bank Account"
                },
                {
                  "accountId" => "223344",
                  "accountNumber" => "556677",
                  "accountName" => "Test User",
                  "referenceName" => "My Private Investec Savings Account",
                  "productName" => "Private Savings Account"
                }
              ]
            }
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

      client.authenticate!
    end

    it "returns all accounts for the authorized user as InvestecOpenApi::Models::Account instances" do
      accounts = client.accounts

      expect(accounts.first).to be_an_instance_of(InvestecOpenApi::Models::Account)

      expect(accounts.first.id).to eq "12345"
      expect(accounts.first.number).to eq "67890"
      expect(accounts.first.name).to eq "Test User"
      expect(accounts.first.reference_name).to eq "My Private Investec Bank Account"
      expect(accounts.first.product_name).to eq "Private Bank Account"

      expect(accounts.last.id).to eq "223344"
      expect(accounts.last.number).to eq "556677"
      expect(accounts.last.name).to eq "Test User"
      expect(accounts.last.reference_name).to eq "My Private Investec Savings Account"
      expect(accounts.last.product_name).to eq "Private Savings Account"
    end
  end

  describe "#transactions" do
    let(:transaction_data) do
      {
        data: {
          transactions: [
            {
              "accountId": "12345",
              "type": "DEBIT",
              "status": "POSTED",
              "description": "MONTHLY SERVICE CHARGE",
              "cardNumber": "",
              "postedOrder": 1,
              "postingDate": "2020-06-11",
              "valueDate": "2020-06-10",
              "actionDate": "2020-06-18",
              "amount": 535
            },
            {
              "accountId": "12345",
              "type": "CREDIT",
              "status": "POSTED",
              "description": "CREDIT INTEREST",
              "cardNumber": "",
              "postedOrder": 2,
              "postingDate": "2020-06-11",
              "valueDate": "2020-06-10",
              "actionDate": "2020-06-18",
              "amount": 31.09
            }
          ]
        }
      }.to_json
    end

    before do
      client.authenticate!
    end

    context "when no filter parameters are specified" do
      before do
        stub_request(:get, "#{api_url}za/pb/v1/accounts/12345/transactions")
          .with(body: "", headers: headers)
          .to_return(
            body: transaction_data,
            headers: {
              "Content-Type" => "application/json"
            })
      end

      it "returns all transactions for the specified account id as InvestecOpenApi::Models::Transaction instances" do
        transactions = client.transactions("12345")
        expect(transactions.first).to be_an_instance_of(InvestecOpenApi::Models::Transaction)
      end
    end

    context "when filter parameters are specified" do
      let(:options) { { from_date: "2021-01-01", to_date: "2023-01-01", page: 4 } }

      before do
        stub_request(:get, "#{api_url}za/pb/v1/accounts/12345/transactions?fromDate=2021-01-01&toDate=2023-01-01&page=4")
          .with(body: "", headers: headers)
          .to_return(
            body: transaction_data,
            headers: {
              "Content-Type" => "application/json"
            })
      end

      it "returns all transactions for the specified account id as InvestecOpenApi::Models::Transaction instances" do
        transactions = client.transactions("12345", options)
        expect(transactions.first).to be_an_instance_of(InvestecOpenApi::Models::Transaction)
      end
    end
  end

  describe "#pending_transactions" do
    let(:account_id) { Faker::Number.number(digits: 10).to_s }
    let(:pending_transaction_data) do
      {
        data: {
          transactions: [
            {
              accountId: account_id,
              type: "DEBIT",
              status: "PENDING",
              description: Faker::Lorem.sentence(word_count: 3),
              transactionDate: Faker::Date.between(from: Date.today - 2, to: Date.today).to_s,
              amount: Faker::Number.decimal(l_digits: 2)
            },
            {
              accountId: account_id,
              type: "DEBIT",
              status: "PENDING",
              description: Faker::Lorem.sentence(word_count: 3),
              transactionDate: Faker::Date.between(from: Date.today - 5, to: Date.today - 3).to_s,
              amount: Faker::Number.decimal(l_digits: 2)
            }
          ]
        }
      }
    end

    context "when no filter parameters are specified" do
      before do
        stub_request(:get, "#{api_url}za/pb/v1/accounts/#{account_id}/pending-transactions")
          .with(headers: headers)
          .to_return(
            body: pending_transaction_data.to_json,
            headers: {
              "Content-Type" => "application/json"
            })
        client.authenticate!
      end

      it "should not filter out any results" do
        transactions = client.pending_transactions(account_id)
        transactions.each_index do |index|
          expect(transactions[index]).to be_an_instance_of(InvestecOpenApi::Models::Transaction)
          expect(transactions[index].description)
            .to eq(pending_transaction_data[:data][:transactions][index][:description])
        end
      end
    end

    context "when filter parameters are specified" do
      let(:options) { { from_date: "2024-01-01", to_date: "2024-02-01" } }
      before do
        stub_request(
          :get,
          "#{api_url}za/pb/v1/accounts/#{account_id}/pending-transactions?fromDate=2024-01-01&toDate=2024-02-01"
        )
          .with(headers: headers)
          .to_return(
            body: pending_transaction_data.to_json,
            headers: {
              "Content-Type" => "application/json"
            })
        client.authenticate!
      end

      it "should filter out results based on options object" do
        transactions = client.pending_transactions(account_id, options)
        transactions.each_index do |index|
          expect(transactions[index]).to be_an_instance_of(InvestecOpenApi::Models::Transaction)
          expect(transactions[index].description)
            .to eq(pending_transaction_data[:data][:transactions][index][:description])
        end
      end
    end
  end

  describe "#transfer_multiple" do
    let(:account_id) { Faker::Number.number(digits: 10).to_s }
    let(:beneficiary_account_id) { Faker::Number.number(digits: 10).to_s }
    let(:transfer_amount) { Faker::Number.decimal(l_digits: 2) }
    let(:my_reference) { Faker::Lorem.words(number: 5).join(" ") }
    let(:their_reference) { Faker::Lorem.words(number: 5).join(" ") }
    let(:transfer_response) do
      {
        "PaymentReferenceNumber" => Faker::Lorem.words(number: 5).join(" "),
        "PaymentDate" => Date.today.to_s,
        "Status" => "- No authorisation necessary <BR>- Payment/Transfer effective date #{Date.today}",
        "BeneficiaryName" =>  "Transfer Test",
        "BeneficiaryAccountId" => beneficiary_account_id,
        "AuthorisationRequired" => false
      }
    end
    let(:response_body) do
      {
        "TransferResponse" => [transfer_response],
        "links" => {
          "self" => "https://openapisandbox.investec.com/za/pb/v1/accounts/3353431574710163189587446/transfermultiple"
        },
        "meta" => {
          "totalPages" => 1
        }
      }
    end

    before do
      client.authenticate!
      stub_request(:post, "#{api_url}za/pb/v1/accounts/#{account_id}/transfermultiple")
        .with(
          body: {
            transferList: [{
                             beneficiaryAccountId: beneficiary_account_id,
                             amount: transfer_amount.to_s,
                             myReference: my_reference,
                             theirReference: their_reference
                           }]
          },
          headers: headers
        )
        .to_return(
          body: response_body.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    it "returns a response with the transfer details" do
      transfer = InvestecOpenApi::Models::Transfer.new(
        beneficiary_account_id,
        transfer_amount,
        my_reference,
        their_reference
      )
      result = client.transfer_multiple(account_id, [transfer])
      expect(result).to eq response_body
    end
  end

  describe "#create_fixed_term_deposit" do
    let(:account_id) { Faker::Number.number(digits: 10).to_s }
    let(:product_id) { "32DayNotice" }
    let(:amount) { Faker::Number.decimal(l_digits: 5, r_digits: 2) }
    let(:external_reference) { "MyFTD-#{Faker::Number.number(digits: 5)}" }
    
    let(:ftd_response) do
      {
        data: {
          id: "ftd#{Faker::Number.number(digits: 8)}",
          startDate: Date.today.to_s,
          endDate: (Date.today + 32).to_s,
          productType: "32 Day Notice",
          interestRatePercent: 5.75,
          currency: "ZAR",
          amount: amount,
          status: "ACTIVE",
          externalReference: external_reference
        },
        meta: nil
      }
    end

    before do
      client.authenticate!
      
      stub_request(:post, "#{api_url}uk/bb/v1/fixedtermdeposits")
        .with(
          body: {
            productId: product_id,
            amount: amount.to_s,
            externalreference: external_reference
          }.to_json,
          headers: headers.merge({
            'Content-Type' => 'application/json'
          })
        )
        .to_return(
          body: ftd_response.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    it "creates a fixed term deposit and returns the result as an InvestecOpenApi::Models::FixedTermDeposit instance" do
      ftd = client.create_fixed_term_deposit(
        product_id, 
        amount, 
        external_reference
      )
      
      expect(ftd).to be_an_instance_of(InvestecOpenApi::Models::FixedTermDeposit)
      expect(ftd.id).to eq ftd_response[:data][:id]
      expect(ftd.product_type).to eq ftd_response[:data][:productType]
      expect(ftd.amount.to_f).to eq ftd_response[:data][:amount]
      expect(ftd.external_reference).to eq external_reference
      expect(ftd.interest_rate_percent).to eq ftd_response[:data][:interestRatePercent]
      expect(ftd.status).to eq ftd_response[:data][:status]
    end
  end

  describe "#products" do
    let(:products_data) do
      {
        data: [
          {
            id: "32DayNotice",
            name: "32 Day Notice Account",
            currency: "GBP",
            type: "NoticeSavings",
            aer: 4.25,
            grossRate: 4.17,
            description: "A 32 day notice account",
            term: "32 days",
            startdate: "2024-01-01",
            endDate: "2024-12-31"
          },
          {
            id: "90DayFixed",
            name: "90 Day Fixed Term Deposit",
            currency: "GBP",
            type: "FixedTerm",
            aer: 4.75,
            grossRate: 4.65,
            description: "A 90 day fixed term deposit",
            term: "90 days",
            startdate: "2024-01-01",
            endDate: "2024-12-31"
          }
        ]
      }.to_json
    end

    before do
      client.authenticate!
      stub_request(:get, "#{api_url}uk/bb/v1/products")
        .with(headers: headers)
        .to_return(
          body: products_data,
          headers: {
            "Content-Type" => "application/json"
          })
    end

    it "returns available products as InvestecOpenApi::Models::Product instances" do
      products = client.products
      
      expect(products.length).to eq 2
      expect(products.first).to be_an_instance_of(InvestecOpenApi::Models::Product)
      expect(products.first.id).to eq "32DayNotice"
      expect(products.first.name).to eq "32 Day Notice Account"
      expect(products.first.gross_rate).to eq 4.17
      
      expect(products.last.id).to eq "90DayFixed"
      expect(products.last.name).to eq "90 Day Fixed Term Deposit"
    end
  end

  describe "#product" do
    let(:product_id) { "32DayNotice" }
    let(:product_data) do
      {
        data: {
          id: "32DayNotice",
          name: "32 Day Notice Account",
          currency: "GBP",
          type: "NoticeSavings",
          aer: 4.25,
          grossRate: 4.17,
          description: "A 32 day notice account",
          term: "32 days",
          startdate: "2024-01-01",
          endDate: "2024-12-31"
        },
        meta: nil
      }.to_json
    end

    before do
      client.authenticate!
      stub_request(:get, "#{api_url}uk/bb/v1/products/#{product_id}")
        .with(headers: headers)
        .to_return(
          body: product_data,
          headers: {
            "Content-Type" => "application/json"
          })
    end

    it "returns the specific product as an InvestecOpenApi::Models::Product instance" do
      product = client.product(product_id)
      
      expect(product).to be_an_instance_of(InvestecOpenApi::Models::Product)
      expect(product.id).to eq "32DayNotice"
      expect(product.name).to eq "32 Day Notice Account"
      expect(product.currency).to eq "GBP"
      expect(product.type).to eq "NoticeSavings"
      expect(product.aer).to eq 4.25
      expect(product.gross_rate).to eq 4.17
      expect(product.description).to eq "A 32 day notice account"
      expect(product.term).to eq "32 days"
    end

    context "when the product does not exist" do
      let(:non_existent_product_id) { "NonExistentProduct" }
      
      before do
        stub_request(:get, "#{api_url}uk/bb/v1/products/#{non_existent_product_id}")
          .with(headers: headers)
          .to_return(
            body: { data: nil, meta: nil }.to_json,
            headers: {
              "Content-Type" => "application/json"
            })
      end
      
      it "returns nil" do
        product = client.product(non_existent_product_id)
        expect(product).to be_nil
      end
    end
  end
end
