#!/usr/bin/env ruby
# fund_management/venus_fund_specialized.rb

require_relative "utilities"

class Asset
  attr_reader :name, :quantity, :purchase_price
  attr_accessor :current_price

  def initialize(name:, quantity:, purchase_price:)
    @name           = name
    @quantity       = quantity
    @purchase_price = purchase_price
    @current_price  = purchase_price
  end

  def current_value
    @quantity * @current_price
  end
end

class VenusFund
  attr_reader :cash, :assets, :investors

  def initialize(initial_capital)
    @cash      = initial_capital
    @assets    = []
    @investors = []
  end

  def add_investor(amount)
    @investors << amount
    @cash     += amount
  end

  def purchase_asset(name:, amount:, price_per_unit:)
    quantity = amount / price_per_unit
    @assets << Asset.new(
      name:           name,
      quantity:       quantity,
      purchase_price: price_per_unit
    )
    @cash -= amount
  end

  def update_asset_prices(prices)
    @assets.each do |asset|
      asset.current_price = prices[asset.name]
    end
  end

  def total_value
    @assets.sum(&:current_value) + @cash
  end

  def process_withdrawal(index, percentage)
    amount         = @investors[index] * percentage
    nav_multiplier = total_value / @investors.sum
    payout         = amount * nav_multiplier
    @investors[index] -= amount
    @cash          -= payout
    payout
  end

  def calculate_waterfall(hurdle_rate: 0.10, target_rate: 0.27,
                          gp_share_low: 0.20, gp_share_high: 0.30)
    fund_value     = total_value
    starting_value = @investors.sum
    annual_profit  = fund_value - starting_value

    hurdle_amount      = starting_value * hurdle_rate
    profit_after_hurdle = annual_profit - hurdle_amount

    return_rate = annual_profit / starting_value
    gp_share    = return_rate >= target_rate ? gp_share_high : gp_share_low

    gp_profit       = profit_after_hurdle * gp_share
    investor_profit = profit_after_hurdle * (1 - gp_share)

    {
      total_value:     fund_value,
      investor_return: starting_value + hurdle_amount + investor_profit,
      gp_profit:       gp_profit
    }
  end
end

# Simulation
fund = VenusFund.new(0)

# a. Initial Investment
3.times { fund.add_investor(100_000) }

# b. Asset Purchase
fund.purchase_asset(name: "BTC", amount: 250_000, price_per_unit: 13_000)

# c. Additional Investors
2.times { fund.add_investor(100_000) }

# d. Additional Asset Purchase
fund.purchase_asset(name: "ETH", amount: 150_000, price_per_unit: 150)

# e. Further Asset Purchase
fund.purchase_asset(name: "TSLA", amount: 100_000, price_per_unit: 60)

# f. Withdrawals
fund.update_asset_prices({ "BTC" => 29_000, "ETH" => 730, "TSLA" => 700 })
withdrawal_1 = fund.process_withdrawal(0, 1.0)
withdrawal_2 = fund.process_withdrawal(1, 0.5)

puts "2020 Withdrawals:"
puts "Investor 1: #{withdrawal_1.to_money}"
puts "Investor 2: #{withdrawal_2.to_money}"

# g. Asset Pricing and Waterfall Calculations
fund.update_asset_prices({ "BTC" => 47_000, "ETH" => 3_800, "TSLA" => 1_100 })
result = fund.calculate_waterfall

puts "\n2021 Results:"
puts "Total Fund Value: #{result[:total_value].to_money}"
puts "Investor Return:  #{result[:investor_return].to_money}"
puts "GP Profit:        #{result[:gp_profit].to_money}"
