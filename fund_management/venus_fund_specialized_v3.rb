#!/usr/bin/env ruby
# fund_management/venus_fund_specialized_v3.rb

require 'amazing_print'

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

  def to_s
    "#{@name} #{current_value.to_money} quantity #{quantity} units at $#{@current_price})"
  end
end

class VenusFund
  ANNUAL_INTEREST_RATE = 0.05 # Cash money market interest rate

  attr_reader :cash, :assets, :investors, :year, :gp_accumulated_profit

  def initialize
    @cash = 0
    @assets = []
    @investors = [] # Tracks each investor's capital contribution
    @year = 2017
    @gp_accumulated_profit = 0
  end

  def add_investor(amount)
    @investors << amount
    @cash += amount
  end

  def purchase_asset(name:, amount:, price_per_unit:)
    return if amount > @cash

    quantity = amount / price_per_unit
    @assets << Asset.new(name: name, quantity: quantity, purchase_price: price_per_unit)
    @cash -= amount
  end

  def update_asset_prices(prices)
    @assets.each do |asset|
      asset.current_price = prices[asset.name] if prices.key?(asset.name)
    end
  end

  def total_asset_value
    @assets.sum(&:current_value)
  end

  def total_value
    total_asset_value + @cash
  end

  def process_withdrawal(index, percentage)
    return 0 if index >= @investors.length || percentage <= 0 || percentage > 1

    # Calculate investor's proportional ownership of the fund
    total_invested = @investors.sum
    investor_proportion = @investors[index] / total_invested

    # Calculate withdrawal amount based on current NAV
    withdrawal_proportion = investor_proportion * percentage
    withdrawal_amount = total_value * withdrawal_proportion

    # Handle cash shortfall if needed
    if @cash < withdrawal_amount
      shortfall = withdrawal_amount - @cash
      liquidate_assets_proportionally(shortfall)
    end

    # Update investor records
    @investors[index] *= (1 - percentage)
    @investors.delete_at(index) if @investors[index] < 0.01 # Remove if effectively zero

    # Update cash
    @cash -= withdrawal_amount

    withdrawal_amount
  end

  def liquidate_assets_proportionally(amount_needed)
    return 0 if total_asset_value == 0 || amount_needed <= 0

    proportion_to_liquidate = [amount_needed / total_asset_value, 1.0].min

    liquidated_amount = 0
    @assets.each do |asset|
      cash_from_asset = asset.liquidate(proportion_to_liquidate)
      liquidated_amount += cash_from_asset
      @cash += cash_from_asset
    end

    # Clean up any empty assets
    @assets.reject! { |asset| asset.quantity < 0.000001 }

    liquidated_amount
  end

  def calculate_annual_waterfall(hurdle_rate: 0.08, target_rate: 0.20, gp_share_low: 0.20, gp_share_high: 0.30)
    starting_value = @investors.sum
    current_value = total_value

    return {
      total_value: current_value,
      investor_return: current_value,
      gp_profit: 0,
      annual_return: 0
    } if starting_value == 0

    # Calculate annual return
    annual_return = (current_value / starting_value) - 1

    # Calculate profit and hurdle
    profit = current_value - starting_value
    hurdle_amount = starting_value * hurdle_rate

    # Calculate carry
    profit_after_hurdle = [profit - hurdle_amount, 0].max
    gp_share_rate = annual_return >= target_rate ? gp_share_high : gp_share_low

    gp_profit = profit_after_hurdle * gp_share_rate
    @gp_accumulated_profit += gp_profit

    investor_return = current_value - gp_profit

    # Adjust investor capital for next year - their capital grows by the return rate
    if @investors.any?
      investor_return_rate = investor_return / starting_value
      @investors = @investors.map { |capital| capital * investor_return_rate }
    end

    # Pay GP profit from cash
    if @cash >= gp_profit
      @cash -= gp_profit
    else
      # Need to liquidate assets to pay GP
      shortfall = gp_profit - @cash
      liquidate_assets_proportionally(shortfall)
      @cash -= gp_profit
    end

    {
      total_value: current_value,
      investor_return: investor_return,
      gp_profit: gp_profit,
      annual_return: annual_return
    }
  end

  def advance_year
    interest = @cash * ANNUAL_INTEREST_RATE
    @cash += interest
    puts "EOY #{@year}: Interest at #{ANNUAL_INTEREST_RATE*100.0}% was #{interest.to_money} bringing Cash Account Total to #{@cash.to_money}"

    puts "EOY Assets:"
    @assets.each { |asset| puts asset }

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
fund.advance_year
puts "\n2018: BTC Purchase"
fund.purchase_asset(name: "BTC", amount: 250_000, price_per_unit: 13_000)
fund.update_asset_prices({ "BTC" => 13_000 })
puts "Fund Value after BTC Purchase: #{fund.total_value.to_money}"

# c & d & e. Additional Investors and Purchases (2019)
fund.advance_year
puts "\n2019: New Investors and Asset Purchases"
2.times { fund.add_investor(100_000) }
# BTC crashed in 2019
fund.update_asset_prices({ "BTC" => 3_500 }) # BTC low in early 2019
puts "Fund Value after BTC crash: #{fund.total_value.to_money}"

fund.purchase_asset(name: "ETH", amount: 150_000, price_per_unit: 150)  # ETH ~$150 mid-2019
fund.purchase_asset(name: "TSLA", amount: 100_000, price_per_unit: 60)  # TSLA ~$60 pre-split mid-2019
fund.update_asset_prices({ "BTC" => 7_200, "ETH" => 150, "TSLA" => 60 })  # BTC recover to ~$7.2k EOY 2019
result = fund.calculate_annual_waterfall
puts "Total Fund Value: #{result[:total_value].to_money}"
puts "Investor Return:  #{result[:investor_return].to_money}"
puts "GP Profit:        #{result[:gp_profit].to_money}"
puts "Annual Return:    #{(result[:annual_return] * 100).round(2)}%"

# f. Withdrawals (2020)
fund.advance_year
puts "\n2020: Withdrawals"
fund.update_asset_prices({ "BTC" => 29_000, "ETH" => 730, "TSLA" => 700 })  # Prices: BTC ~$29k, ETH ~$730, TSLA ~$700 EOY 2020
puts "Fund Value before withdrawals: #{fund.total_value.to_money}"
withdrawal_1 = fund.process_withdrawal(0, 1.0)
withdrawal_2 = fund.process_withdrawal(1, 0.5)
puts "Investor 1 Withdrawal: #{withdrawal_1.to_money}"
puts "Investor 2 Withdrawal (50%): #{withdrawal_2.to_money}"
puts "Fund Value after withdrawals: #{fund.total_value.to_money}"
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
puts "GP Accumulated Profit: #{fund.gp_accumulated_profit.to_money}"
