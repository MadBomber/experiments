#!/usr/bin/env ruby
# venus_fund_specialized_v5.rb
require 'date'

require 'debug_me'
include DebugMe

require_relative 'utilities'

class VenusFund
  attr_accessor :cash, :assets, :investors, :gp_accumulated_profit, :hurdle_rate, :target_return, :gp_profit_share_above_hurdle, :gp_profit_share_above_target, :year

  def initialize(year = 2017, hurdle_rate: 0.10, target_return: 0.27, gp_profit_share_above_hurdle: 0.20, gp_profit_share_above_target: 0.30, adjust_investor_capital: false, liquidation_strategy: :proportional)
    @year = year
    @cash = 0.0
    @assets = {}  # { asset_name => { quantity: x, purchase_price: y } }
    @investors = {}  # { investor_name => capital }
    @gp_accumulated_profit = 0.0
    @hurdle_rate = hurdle_rate
    @target_return = target_return
    @gp_profit_share_above_hurdle = gp_profit_share_above_hurdle
    @gp_profit_share_above_target = gp_profit_share_above_target
    @cumulative_return = 0.0
    @adjust_investor_capital = adjust_investor_capital
    @liquidation_strategy = liquidation_strategy

    puts "Venus Fund initialized for #{@year}."
    puts "Hurdle Rate: #{@hurdle_rate}, Target Return: #{@target_return}"
    puts "GP Profit Share (Above Hurdle): #{@gp_profit_share_above_hurdle}, GP Profit Share (Above Target): #{@gp_profit_share_above_target}"
    puts "Liquidation Strategy: #{@liquidation_strategy}"
    puts "Adjust Investor Capital: #{@adjust_investor_capital}"
    puts "--------------------"
  end

  def add_investor(name, capital)
    @investors[name] = capital
    @cash += capital
    puts "#{@year}: Investor #{name} added with capital #{capital.to_money}. Cash: #{@cash.to_money}"
  end

  def purchase_asset(asset_name, quantity, price)
    total_cost = quantity * price
    if @cash >= total_cost
      @assets[asset_name] ||= { quantity: 0.0, purchase_price: price, current_price: price }
      @assets[asset_name][:quantity] += quantity
      @assets[asset_name][:purchase_price] = price
      @cash -= total_cost
      puts "#{@year}: Purchased #{quantity} #{asset_name} at #{price.to_money} for #{total_cost.to_money}. Remaining cash: #{@cash.to_money}"
    else
      puts "#{@year}: Insufficient cash to purchase #{quantity} #{asset_name} at #{price.to_money}."
    end
  end

  def update_asset_price(asset_name, new_price)
    if @assets[asset_name]
      @assets[asset_name][:current_price] = new_price
      puts "#{@year}: Updated price of #{asset_name} to #{new_price.to_money}"
    else
      puts "#{@year}: Asset #{asset_name} not found in portfolio."
    end
  end

  def investor_withdrawal(name, percentage)
    if @investors.key?(name)
      current_value = investor_current_value(name)
      withdrawal_amount = current_value * percentage

      puts "#{@year}: Investor #{name} requests withdrawal of #{(percentage * 100).round(1)}% (Value: #{current_value.to_money}, Withdrawal Amount: #{withdrawal_amount.to_money})"
      withdraw(name, withdrawal_amount, percentage)
    else
      puts "#{@year}: Investor #{name} not found."
    end
  end

  def withdraw(name, amount, percentage)
    available_cash = @cash
    asset_value = total_asset_value()
    total_value = available_cash + asset_value

    if total_value < amount
      puts "#{@year}: Insufficient funds (cash + assets) to fulfill withdrawal of #{amount.to_money}."
      return
    end

    # First use available cash
    if available_cash >= amount
      @cash -= amount
      adjust_investor_capital(name, percentage)
      puts "#{@year}: Investor #{name} withdrew #{amount.to_money} from cash. Remaining cash: #{@cash.to_money}"
    else
      cash_used = available_cash
      puts "#{@year}: Investor #{name} withdrew #{cash_used.to_money} from cash. Remaining cash: $0.00 Liquidating assets for the remaining amount of #{(amount - cash_used).to_money}."
      amount -= cash_used
      @cash = 0.0
      liquidate_proportionally(amount, name, percentage)
    end
  end

  def liquidate_proportionally(liquidation_needed, investor_name, percentage)
    total_asset_value = total_asset_value()

    @assets.each do |asset_name, asset|
      current_price = asset[:current_price]
      quantity = asset[:quantity]
      asset_proportion = (current_price * quantity) / total_asset_value
      units_to_sell = (liquidation_needed * asset_proportion) / current_price
      puts "Units to Sell #{units_to_sell}"

      if units_to_sell > quantity
        units_to_sell = quantity
        puts "#{@year}: Not enough assets for liquidation needed, liquidating maximum units for #{asset_name}"
      end

      sale_proceeds = units_to_sell * current_price
      puts "#{@year}: Selling #{units_to_sell} units of #{asset_name} for #{sale_proceeds.to_money}"
      @cash += sale_proceeds
      asset[:quantity] -= units_to_sell
      liquidation_needed -= sale_proceeds

      if asset[:quantity] <= 0
        @assets.delete(asset_name)
      end
    end

    adjust_investor_capital(investor_name, percentage)
    puts "#{@year}: After Liquidation Cash is #{@cash.to_money}"
  end

  def adjust_investor_capital(name, percentage)
    if percentage >= 1.0
      @investors[name] = 0.0
      puts "#{@year}: Investor #{name} capital set to #{@investors[name].to_money} (full withdrawal)"
    else
      @investors[name] *= (1.0 - percentage)
      puts "#{@year}: Investor #{name} capital reduced by #{(percentage * 100).to_i}% to #{@investors[name].to_money}"
    end
  end

  def calculate_returns
    initial_capital = @investors.values.sum
    current_value = @cash + total_asset_value()
    total_return = current_value - initial_capital
    return_percentage = total_return / initial_capital
    puts "#{@year}: Initial Capital: #{initial_capital.to_money}, Current Value: #{current_value.to_money}, Total Return: #{total_return.to_money}, Return Percentage: #{(return_percentage*100).round(1)}%"
    return_percentage
  end

  def total_asset_value
    result = @assets.values.map { |asset| asset[:quantity] * asset[:current_price] }.sum

    # debug_me{[
    #   :result,
    #   '@cash'
    # ]}

    result
  end

  def investor_current_value(name)
    total_fund_value = @cash + total_asset_value
    investor_proportion = Float(@investors[name]) / Float(@investors.values.sum)
    # debug_me{[
    #   :total_fund_value,
    #   :investor_proportion
    # ]}
    total_fund_value * investor_proportion
  end

  def perform_waterfall
    puts "#{@year}: Performing waterfall calculation..."
    current_value = @cash + total_asset_value()
    initial_capital = @investors.values.sum
    total_return = current_value - initial_capital
    return_percentage = total_return / initial_capital

    hurdle_amount = initial_capital * @hurdle_rate
    puts "#{@year}: Hurdle Amount #{hurdle_amount.to_money}"

    gp_profit = 0.0
    if total_return > hurdle_amount
      above_hurdle = total_return - hurdle_amount
      gp_profit = above_hurdle * @gp_profit_share_above_hurdle

      if return_percentage > @target_return
        above_target = total_return - (initial_capital * @target_return)
        gp_profit = (above_hurdle - above_target) * @gp_profit_share_above_hurdle + (above_target * @gp_profit_share_above_target)
        puts "#{@year}: Target Return Achieved! GP Profit share set to #{@gp_profit_share_above_target * 100}% for amounts above target."
      end
      puts "#{@year}: GP Profit: #{gp_profit.to_money}"
    else
      puts "#{@year}: Did not reach hurdle. No GP profit this year."
    end

    if @cash >= gp_profit
      @cash -= gp_profit
      @gp_accumulated_profit += gp_profit
      puts "#{@year}: Paid GP #{gp_profit.to_money} from cash. Remaining cash: #{@cash.to_money}"
    else
      puts "#{@year}: Insufficient cash to pay GP profit of #{gp_profit.to_money}. GP profit is accrued."
      @gp_accumulated_profit += gp_profit
    end
  end

  def end_year
    puts "#{@year}: ----- End of Year Summary -----"
    puts "#{@year}: Cash: #{@cash.to_money}"
    puts "#{@year}: Total Asset Value: #{total_asset_value.to_money}"

    @assets.each do |asset_name, asset|
      puts "#{@year}: #{asset_name}: Quantity: #{asset[:quantity]}, Purchase Price: #{asset[:purchase_price].to_money}, Current Price: #{asset[:current_price].to_money}"
    end

    @investors.each do |name, capital|
      puts "#{@year}: Investor #{name} capital: #{capital.to_money}"
    end

    puts "#{@year}: GP Accumulated Profit: #{@gp_accumulated_profit.to_money}"
    calculate_returns
    puts "#{@year}: ----- End of Year -----"
    puts
    @year += 1
  end
end

# Simulation
puts "================="
puts "== Vensus Fund =="
puts "== VanHoozer   =="
puts "================="
puts

fund = VenusFund.new(2017, adjust_investor_capital: false, liquidation_strategy: :proportional)

# 2017
fund.add_investor("Larry", 100_000)
fund.add_investor("Curly", 100_000)
fund.add_investor("Moe", 100_000)
fund.end_year

# 2018
fund.purchase_asset("BTC", 19, 13_000)
fund.perform_waterfall
fund.end_year

# 2019
fund.add_investor("Abbott", 100_000)
fund.add_investor("Costello", 100_000)
fund.purchase_asset("ETH", 1_000, 150)
fund.purchase_asset("TSLA", 1_666, 60)
fund.update_asset_price("BTC", 7_200)
fund.end_year

# 2020
fund.update_asset_price("BTC", 29_000)
fund.update_asset_price("ETH", 730)
fund.update_asset_price("TSLA", 700)
fund.investor_withdrawal("Larry", 1.0)
fund.investor_withdrawal("Curly", 0.5)
fund.perform_waterfall
fund.end_year

# 2021
fund.update_asset_price("BTC", 47_000)
fund.update_asset_price("ETH", 3_800)
fund.update_asset_price("TSLA", 1_100)
fund.perform_waterfall
fund.end_year
