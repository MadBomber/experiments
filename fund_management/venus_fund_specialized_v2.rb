#!/usr/bin/env ruby
# fund_management/venus_fund_specialized_v2.rb

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

  def liquidate(percentage)
    liquidated_quantity = @quantity * percentage
    @quantity -= liquidated_quantity
    liquidated_quantity * @current_price
  end
end

class VenusFund
  attr_reader :cash, :assets, :investors, :year

  def initialize
    @cash      = 0
    @assets    = []
    @investors = [] # Tracks each investor's capital contribution
    @year      = 2017
  end

  def add_investor(amount)
    @investors << amount
    @cash += amount
  end

  def purchase_asset(name:, amount:, price_per_unit:)
    quantity = amount / price_per_unit
    @assets << Asset.new(name: name, quantity: quantity, purchase_price: price_per_unit)
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
    investor_amount = @investors[index] * percentage
    nav_multiplier = total_value / @investors.sum
    payout = investor_amount * nav_multiplier

    if @cash < payout
      shortfall = payout - @cash
      liquidate_assets(shortfall)
    end

    @investors[index] -= investor_amount
    @investors.delete_at(index) if @investors[index].zero?
    @cash -= payout
    payout
  end

  def liquidate_assets(amount)
    total_asset_value = @assets.sum(&:current_value)
    return if total_asset_value.zero?

    @assets.each do |asset|
      proportion = asset.current_value / total_asset_value
      liquidation_amount = amount * proportion
      @cash += asset.liquidate(liquidation_amount / asset.current_value)
    end
  end

  def calculate_annual_waterfall(hurdle_rate: 0.10, target_rate: 0.27, gp_share_low: 0.20, gp_share_high: 0.30)
    starting_value = @investors.sum
    return { total_value: starting_value, investor_return: starting_value, gp_profit: 0 } if starting_value.zero?

    fund_value = total_value
    annual_return = (fund_value / starting_value) - 1 # Return for the year
    hurdle_amount = starting_value * hurdle_rate
    profit = fund_value - starting_value

    profit_after_hurdle = [profit - hurdle_amount, 0].max
    gp_share = annual_return >= target_rate ? gp_share_high : gp_share_low

    gp_profit = profit_after_hurdle * gp_share
    investor_profit = profit_after_hurdle * (1 - gp_share)
    investor_return = starting_value + hurdle_amount + investor_profit

    # Adjust investor capital for next year
    @investors = @investors.map { |capital| capital * (investor_return / starting_value) }
    @cash = investor_return # Simplified: cash reflects investor returns after GP take

    {
      total_value: fund_value,
      investor_return: investor_return,
      gp_profit: gp_profit,
      annual_return: annual_return
    }
  end

  def advance_year
    @year += 1
  end
end

# Simulation
fund = VenusFund.new

# a. Initial Investment (2017)
puts "\n2017: Initial Investment"
3.times { fund.add_investor(100_000) }
puts "Starting Capital: #{fund.total_value.to_money}"

# b. Asset Purchase (2018)
# BTC ~$13,000 in Jan 2018 (CoinMarketCap avg)
fund.advance_year
puts "\n2018: BTC Purchase"
fund.purchase_asset(name: "BTC", amount: 250_000, price_per_unit: 13_000)
fund.update_asset_prices({ "BTC" => 13_000 })
puts "Fund Value after BTC Purchase: #{fund.total_value.to_money}"

# c & d & e. Additional Investors and Purchases (2019)
fund.advance_year
puts "\n2019: New Investors and Asset Purchases"
2.times { fund.add_investor(100_000) }
fund.purchase_asset(name: "ETH", amount: 150_000, price_per_unit: 150)  # ETH ~$150 mid-2019
fund.purchase_asset(name: "TSLA", amount: 100_000, price_per_unit: 60)  # TSLA ~$60 pre-split mid-2019
fund.update_asset_prices({ "BTC" => 10_000, "ETH" => 150, "TSLA" => 60 })  # BTC crash to ~$10k EOY 2019
result = fund.calculate_annual_waterfall
puts "Total Fund Value: #{result[:total_value].to_money}"
puts "Investor Return:  #{result[:investor_return].to_money}"
puts "GP Profit:        #{result[:gp_profit].to_money}"
puts "Annual Return:    #{(result[:annual_return] * 100).round(2)}%"

# f. Withdrawals (2020)
fund.advance_year
puts "\n2020: Withdrawals"
fund.update_asset_prices({ "BTC" => 29_000, "ETH" => 730, "TSLA" => 700 })  # Prices: BTC ~$29k, ETH ~$730, TSLA ~$700 EOY 2020
withdrawal_1 = fund.process_withdrawal(0, 1.0)
withdrawal_2 = fund.process_withdrawal(1, 0.5)
puts "Investor 1 Withdrawal: #{withdrawal_1.to_money}"
puts "Investor 2 Withdrawal (50%): #{withdrawal_2.to_money}"
result = fund.calculate_annual_waterfall
puts "Total Fund Value: #{result[:total_value].to_money}"
puts "Investor Return:  #{result[:investor_return].to_money}"
puts "GP Profit:        #{result[:gp_profit].to_money}"
puts "Annual Return:    #{(result[:annual_return] * 100).round(2)}%"

# g. 2021 Results
fund.advance_year
puts "\n2021: Final Results"
fund.update_asset_prices({ "BTC" => 47_000, "ETH" => 3_800, "TSLA" => 1_100 })  # Prices: BTC ~$47k, ETH ~$3,800, TSLA ~$1,100 EOY 2021
result = fund.calculate_annual_waterfall
puts "Total Fund Value: #{result[:total_value].to_money}"
puts "Investor Return:  #{result[:investor_return].to_money}"
puts "GP Profit:        #{result[:gp_profit].to_money}"
puts "Annual Return:    #{(result[:annual_return] * 100).round(2)}%"
