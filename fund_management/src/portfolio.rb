# src/portfolio.rb

require 'json'
require_relative 'asset'
require_relative 'transaction'

# Portfolio class manages assets owned by a Fund, including
# a cash asset where 1 share always equals 1 dollar
class Portfolio
  attr_reader :assets, :name

  CASH_ASSET_NAME = 'Cash'

  def initialize(name: "general")
    @name   = name
    @assets = {
      CASH_ASSET_NAME => Asset.new(name: CASH_ASSET_NAME)
    }
  end

  def buy(asset_name:, quantity:, price:)
    asset      = @assets[asset_name] ||= Asset.new(name: asset_name)
    total_cost = quantity * price
    cash_asset = @assets[CASH_ASSET_NAME]

    raise 'Insufficient funds' if cash_asset.current_value < total_cost

    asset.buy(quantity:, price:)
    cash_asset.sell(quantity: total_cost)
    Transaction.log(
      type:     :portfolio,
      name:     name,
      action:   :buy,
      asset:    asset_name,
      quantity:,
      price:
    )
  end

  def sell(asset_name:, quantity:)
    asset = @assets[asset_name]
    raise ArgumentError, "Asset not found" unless asset

    current_price = asset.current_price
    proceeds      = quantity * current_price
    asset.sell(quantity:)
    cash_asset    = @assets[CASH_ASSET_NAME]
    cash_asset.buy(quantity: proceeds, price: 1)
    Transaction.log(
      type:     :portfolio,
      action:   :sell,
      asset:    asset_name,
      quantity:,
      price:    current_price
    )
    proceeds
  end

  def save(filename:)
    File.write(filename, to_json)
  end

  def self.load(filename:)
    json_data = File.read(filename)
    from_json(json_data)
  end

  def balance
    total_value            = total_portfolio_value - cash_value
    non_cash_assets        = @assets.reject { |name, _| name == CASH_ASSET_NAME }
    target_value_per_asset = total_value / non_cash_assets.size

    non_cash_assets.each do |name, asset|
      current_value = asset.current_value
      if current_value < target_value_per_asset
        buy_to_balance(asset, target_value_per_asset)
      elsif current_value > target_value_per_asset
        sell_to_balance(asset, target_value_per_asset)
      end
    end
  end

  def extract(amount:)
    # Calculate the proportion to extract from each non-cash asset
    total_value     = total_portfolio_value - cash_value
    non_cash_assets = @assets.reject { |name, _| name == CASH_ASSET_NAME }
    proportion      = amount / total_value

    extracted = 0
    non_cash_assets.each do |name, asset|
      extract_amount   = asset.current_value * proportion
      quantity_to_sell = (extract_amount / asset.current_price).floor
      extracted       += sell(asset_name: name, quantity: quantity_to_sell)
    end

    balance
    extracted
  end

  #########################################################
  private

  def total_portfolio_value
    @assets.values.sum(&:current_value)
  end

  def cash_value
    @assets[CASH_ASSET_NAME].current_value
  end

  def buy_to_balance(asset, target_value)
    # Implementation of buying to balance
  end

  def sell_to_balance(asset, target_value)
    # Implementation of selling to balance
  end

  def to_json
    assets_data = @assets.transform_values do |asset|
      {
        name:     asset.name,
        quantity: asset.quantity,
        price:    asset.current_price
      }
    end
    JSON.pretty_generate(assets: assets_data)
  end

  def self.from_json(json_data)
    data     = JSON.parse(json_data)
    portfolio = new

    data['assets'].each do |name, asset_data|
      portfolio.instance_variable_get(:@assets)[name] =
        Asset.new(
          name:     asset_data['name'],
          quantity: asset_data['quantity'],
          price:    asset_data['price']
        )
    end

    portfolio
  end
end
