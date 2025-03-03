require "faraday"
require "investec_open_api/models/account"
require "investec_open_api/models/transaction"
require "investec_open_api/models/balance"
require "investec_open_api/models/fixed_term_deposit"
require "investec_open_api/models/product"
require "investec_open_api/models/transfer"
require "investec_open_api/camel_case_refinement"
require 'base64'

class InvestecOpenApi::Client
  using InvestecOpenApi::CamelCaseRefinement

  def authenticate!
    @token = get_oauth_token["access_token"]
  end

  def accounts
    response = connection.get("za/pb/v1/accounts")
    response.body["data"]["accounts"].map do |account_raw|
      InvestecOpenApi::Models::Account.from_api(account_raw)
    end
  end

  ## Get cleared transactions for an account
  # @param [String] account_id The id of the account to get transactions for
  # @param [Hash] options
  # @option options [String] :fromDate Start date from which to get transactions
  # @option options [String] :toDate End date for transactions
  # @option options [String] :transactionType Type of transaction to filter by eg: CardPurchases, Deposits
  def transactions(account_id, options = {})
    endpoint_url = "za/pb/v1/accounts/#{account_id}/transactions"
    perform_transaction_request(endpoint_url, options)
  end

  ## Get pending transactions for an account
  # @param [String] account_id The id of the account to get pending transactions for
  # @param [Hash] options
  # @option options [String] :fromDate Start date from which to get pending transactions
  # @option options [String] :toDate End date for pending transactions
  def pending_transactions(account_id, options = {})
    endpoint_url = "za/pb/v1/accounts/#{account_id}/pending-transactions"
    perform_transaction_request(endpoint_url, options)
  end

  def balance(account_id)
    endpoint_url = "za/pb/v1/accounts/#{account_id}/balance"
    response = connection.get(endpoint_url)
    raise "Error fetching balance" if response.body["data"].nil?
    InvestecOpenApi::Models::Balance.from_api(response.body["data"])
  end

  # @param [String] account_id
  # @param [Array<InvestecOpenApi::Models::Transfer>] transfers
  def transfer_multiple(
    account_id,
    transfers,
    profile_id = nil
  )
    endpoint_url = "za/pb/v1/accounts/#{account_id}/transfermultiple"
    data = {
      transferList: transfers.map(&:to_h),
    }
    data[:profileId] = profile_id if profile_id
    response = connection.post(
      endpoint_url,
      JSON.generate(data)
    )
    response.body
  end

  # Get available products
  # @return [Array<InvestecOpenApi::Models::Product>] Array of available products
  def products
    endpoint_url = "uk/bb/v1/products"
    response = connection.get(endpoint_url)
    
    if response.body["data"].is_a?(Array)
      response.body["data"].map do |product_raw|
        InvestecOpenApi::Models::Product.from_api(product_raw)
      end
    else
      []
    end
  end

  # Create a fixed term deposit for an account
  # @param [String] account_id The id of the account to create the fixed term deposit for
  # @param [String] product_id The product ID for the type of fixed term deposit
  # @param [Float] amount The amount to deposit
  # @param [String] external_reference A client-defined reference for this fixed term deposit
  # @return [InvestecOpenApi::Models::FixedTermDeposit] The created fixed term deposit
  def create_fixed_term_deposit(product_id, amount, external_reference)
    endpoint_url = "uk/bb/v1/fixedtermdeposits"
    
    data = {
      productId: product_id,
      amount: amount.to_s,
      externalreference: external_reference
    }
    
    response = connection.post(
      endpoint_url,
      JSON.generate(data),
      { 'Content-Type' => 'application/json' }
    )
    
    InvestecOpenApi::Models::FixedTermDeposit.from_api(response.body["data"])
  end

  # Get a specific product by ID
  # @param [String] product_id The ID of the product to retrieve
  # @return [InvestecOpenApi::Models::Product, nil] The product details or nil if not found
  def product(product_id)
    endpoint_url = "uk/bb/v1/products/#{product_id}"
    response = connection.get(endpoint_url)
    
    if response.body["data"]
      InvestecOpenApi::Models::Product.from_api(response.body["data"])
    else
      nil
    end
  end

  private

  def get_oauth_token
    auth_token = ::Base64.strict_encode64("#{InvestecOpenApi.config.client_id}:#{InvestecOpenApi.config.client_secret}")

    response = Faraday.post(
      "#{InvestecOpenApi.config.base_url}identity/v2/oauth2/token",
      { grant_type: "client_credentials" },
      {
        'x-api-key' => InvestecOpenApi.config.api_key,
        'Authorization' => "Basic #{auth_token}"
      }
    )
    
    if response.body.nil? || response.body.empty?
      raise "Authentication failed: Empty response received (HTTP Status: #{response.status})"
    end
    
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise "Authentication failed: Invalid JSON response (HTTP Status: #{response.status}): #{response.body.inspect}\nError: #{e.message}"
    end
  end

  def connection
    @_connection ||= Faraday.new(url: InvestecOpenApi.config.base_url) do |builder|
      if @token
        builder.headers["Authorization"] = "Bearer #{@token}"
      end

      builder.headers["Accept"] = "application/json"
      builder.request :json

      builder.response :raise_error
      builder.response :json

      builder.adapter Faraday.default_adapter
    end
  end

  def perform_transaction_request(endpoint_url, options)
    unless options.empty?
      query_string = URI.encode_www_form(options.camelize)
      endpoint_url += "?#{query_string}"
    end

    response = connection.get(endpoint_url)
    response.body["data"]["transactions"].map do |transaction_raw|
      InvestecOpenApi::Models::Transaction.from_api(transaction_raw)
    end
  end
end
