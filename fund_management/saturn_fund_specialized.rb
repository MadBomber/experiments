#!/usr/bin/env ruby
# src/saturn_fund_specialized.rb
#
# This is a specialized solution to the
# Saturn Fund problem.

require 'amazing_print'

require_relative 'utilities'

class SaturnFund
  FUND_SIZE                  = 100_000_000
  FUND_LIFE                  = 10
  DISCOUNT_RATE              = 0.10
  INVESTMENT_AMOUNT_PER_DEAL = 10_000_000
  NUM_INVESTORS              = 100
  ACQUISITION_VALUE          = 500_000_000
  INVESTOR_HURDLE_MOIC_1     = 1.8
  GP_SHARE_1                 = 0.20
  INVESTOR_HURDLE_MOIC_2     = 2.7
  GP_SHARE_2                 = 0.30

  def initialize
    @investment_per_investor = FUND_SIZE / NUM_INVESTORS
  end

  def calculate_future_value(principal_amount, annual_rate, years)
    principal_amount * (1 + annual_rate)**years
  end

  def calculate_total_profit(future_value, initial_investment)
    future_value - initial_investment
  end

  def calculate_risk_free_profit(initial_investment)
    risk_free_future_value = calculate_future_value(initial_investment,
                                                    DISCOUNT_RATE, FUND_LIFE)
    calculate_total_profit(risk_free_future_value, initial_investment)
  end

  def calculate_real_profit(nominal_profit, risk_free_profit)
    nominal_profit - risk_free_profit
  end

  def calculate_moic(future_value, initial_investment)
    future_value / initial_investment
  end

  def calculate_moic_per_investor(fund_moic, num_investors)
    fund_moic # Same for fund and per investor in this simple scenario
  end

  def calculate_waterfall_distribution(acquisition_value, total_capital_invested)
    hurdle_1_amount = total_capital_invested * INVESTOR_HURDLE_MOIC_1 # 180M
    investors_phase_1 = [acquisition_value, hurdle_1_amount].min
    remaining_value = acquisition_value - investors_phase_1

    hurdle_2_amount = total_capital_invested * INVESTOR_HURDLE_MOIC_2 # 270M
    amount_to_hurdle_2 = hurdle_2_amount - hurdle_1_amount # 90M
    gp_phase_2_max = amount_to_hurdle_2 * GP_SHARE_1 # 18M
    gp_phase_2 = [remaining_value * GP_SHARE_1, gp_phase_2_max].min
    investors_phase_2 = [remaining_value - gp_phase_2, amount_to_hurdle_2].min
    remaining_value -= (gp_phase_2 + investors_phase_2)

    gp_phase_3 = remaining_value * GP_SHARE_2
    investors_phase_3 = remaining_value - gp_phase_3

    {
      investors_phase_1: investors_phase_1, # 180M
      gp_phase_2: gp_phase_2,              # 18M
      investors_phase_2: investors_phase_2, # 90M
      gp_phase_3: gp_phase_3,              # 69M
      investors_phase_3: investors_phase_3  # 161M
    }
  end

  def analyze_base_case
    base_case_return      = 0.15
    base_case_future_value = calculate_future_value(FUND_SIZE,
                                                    base_case_return, FUND_LIFE)
    base_case_nominal_profit = calculate_total_profit(base_case_future_value,
                                                      FUND_SIZE)
    base_case_risk_free_profit = calculate_risk_free_profit(FUND_SIZE)
    base_case_real_profit = calculate_real_profit(base_case_nominal_profit,
                                                  base_case_risk_free_profit)

    {
      future_value:     base_case_future_value,
      nominal_profit:   base_case_nominal_profit,
      risk_free_profit: base_case_risk_free_profit,
      real_profit:      base_case_real_profit
    }
  end

  def calculate_moic_scenarios
    bear_case_return = 0.09
    bull_case_return = 0.21
    base_case_return = 0.15

    bear_case_future_value = calculate_future_value(FUND_SIZE,
                                                    bear_case_return, FUND_LIFE)
    bull_case_future_value = calculate_future_value(FUND_SIZE,
                                                    bull_case_return, FUND_LIFE)
    base_case_future_value = calculate_future_value(FUND_SIZE,
                                                    base_case_return, FUND_LIFE)

    bear_case_moic = calculate_moic(bear_case_future_value, FUND_SIZE)
    bull_case_moic = calculate_moic(bull_case_future_value, FUND_SIZE)
    base_case_moic = calculate_moic(base_case_future_value, FUND_SIZE)

    {
      bear_case: bear_case_moic,
      bull_case: bull_case_moic,
      base_case: base_case_moic
    }
  end
end



puts "================="
puts "== Saturn Fund =="
puts "== VanHoozer   =="
puts "================="
puts


# Usage example:
fund = SaturnFund.new
base_case_results = fund.analyze_base_case
moic_scenarios    = fund.calculate_moic_scenarios
waterfall         = fund.calculate_waterfall_distribution(
                      SaturnFund::ACQUISITION_VALUE, SaturnFund::FUND_SIZE
                    )

puts "Base Case Results:"
ap base_case_results.transform_values(&:to_money)

puts "\nMOIC Scenarios:"
ap moic_scenarios.transform_values{|v| v.round(1).to_s+"x"}

puts "\nWaterfall Distribution:"
ap waterfall.transform_values(&:to_money)
