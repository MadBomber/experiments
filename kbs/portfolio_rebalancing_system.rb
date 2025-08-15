#!/usr/bin/env ruby

require_relative 'rete2'
require 'csv'
require 'date'

class PortfolioRebalancingSystem
  def initialize(csv_file = 'sample_stock_data.csv')
    @engine = ReteII::ReteEngine.new
    @csv_file = csv_file
    @portfolio = {
      cash: 100_000,
      positions: {},
      target_allocations: {
        "Technology" => 0.40,    # 40% target
        "Healthcare" => 0.25,    # 25% target  
        "Finance" => 0.20,       # 20% target
        "Consumer" => 0.15       # 15% target
      },
      sector_mappings: {
        "AAPL" => "Technology",
        "GOOGL" => "Technology", 
        "MSFT" => "Technology",
        "NVDA" => "Technology",
        "TSLA" => "Consumer",
        "META" => "Technology",
        "JNJ" => "Healthcare",
        "PFE" => "Healthcare",
        "JPM" => "Finance",
        "BAC" => "Finance"
      },
      replacement_candidates: {
        "Technology" => ["AAPL", "GOOGL", "MSFT", "NVDA", "META"],
        "Healthcare" => ["JNJ", "PFE", "UNH", "ABT"],
        "Finance" => ["JPM", "BAC", "WFC", "GS"],
        "Consumer" => ["TSLA", "AMZN", "DIS", "NFLX"]
      },
      trades: [],
      rebalancing_history: []
    }
    @current_prices = {}
    @performance_data = Hash.new { |h, k| h[k] = [] }
    setup_rebalancing_rules
  end
  
  def setup_rebalancing_rules
    # Rule 1: Sector Allocation Drift Detection
    allocation_drift_rule = ReteII::Rule.new(
      "sector_allocation_drift",
      conditions: [
        ReteII::Condition.new(:portfolio_allocation, {
          sector: ->(s) { s && s.length > 0 },
          current_weight: ->(w) { w && w > 0 },
          target_weight: ->(t) { t && t > 0 },
          drift_percentage: ->(d) { d && d.abs > 5 } # >5% drift from target
        })
      ],
      action: lambda do |facts, bindings|
        allocation = facts.find { |f| f.type == :portfolio_allocation }
        sector = allocation[:sector]
        current = allocation[:current_weight]
        target = allocation[:target_weight]
        drift = allocation[:drift_percentage]
        
        action = drift > 0 ? "REDUCE" : "INCREASE"
        puts "⚖️  ALLOCATION DRIFT: #{sector}"
        puts "   Current: #{(current * 100).round(1)}%"
        puts "   Target: #{(target * 100).round(1)}%"
        puts "   Drift: #{drift > 0 ? '+' : ''}#{drift.round(1)}%"
        puts "   Action: #{action} #{sector} allocation"
        
        trigger_sector_rebalancing(sector, target, current)
      end,
      priority: 15
    )
    
    # Rule 2: Underperforming Position Replacement
    underperformer_replacement_rule = ReteII::Rule.new(
      "replace_underperformer",
      conditions: [
        ReteII::Condition.new(:position_performance, {
          symbol: ->(s) { s && s.length > 0 },
          relative_performance: ->(p) { p && p < -10 }, # 10% underperformance
          days_held: ->(d) { d && d > 30 }, # Held for more than 30 days
          sector: ->(s) { s && s.length > 0 }
        }),
        ReteII::Condition.new(:replacement_candidate, {
          sector: ->(s) { s && s.length > 0 },
          relative_performance: ->(p) { p && p > 5 }, # 5% outperformance
          momentum_score: ->(m) { m && m > 0.7 }
        })
      ],
      action: lambda do |facts, bindings|
        underperformer = facts.find { |f| f.type == :position_performance }
        candidate = facts.find { |f| f.type == :replacement_candidate }
        
        if underperformer[:sector] == candidate[:sector]
          puts "🔄 POSITION REPLACEMENT: #{underperformer[:symbol]} → #{candidate[:symbol]}"
          puts "   Sector: #{underperformer[:sector]}"
          puts "   Underperformer: #{underperformer[:relative_performance].round(1)}% vs sector"
          puts "   Replacement: #{candidate[:relative_performance].round(1)}% vs sector"
          puts "   Momentum Score: #{candidate[:momentum_score].round(2)}"
          
          execute_position_replacement(underperformer[:symbol], candidate[:symbol])
        end
      end,
      priority: 12
    )
    
    # Rule 3: Correlation Risk Reduction
    correlation_replacement_rule = ReteII::Rule.new(
      "reduce_correlation_risk",
      conditions: [
        ReteII::Condition.new(:correlation_risk, {
          correlation_coefficient: ->(c) { c && c > 0.8 }, # High correlation
          combined_allocation: ->(a) { a && a > 0.25 }, # >25% combined weight
          sector: ->(s) { s && s.length > 0 }
        }),
        ReteII::Condition.new(:replacement_candidate, {
          correlation_with_portfolio: ->(c) { c && c < 0.5 }, # Low correlation
          sector: ->(s) { s && s.length > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        risk = facts.find { |f| f.type == :correlation_risk }
        candidate = facts.find { |f| f.type == :replacement_candidate }
        
        if risk[:sector] == candidate[:sector]
          puts "📊 CORRELATION RISK REDUCTION"
          puts "   High Correlation: #{(risk[:correlation_coefficient] * 100).round(1)}%"
          puts "   Combined Weight: #{(risk[:combined_allocation] * 100).round(1)}%"
          puts "   Replacement Correlation: #{(candidate[:correlation_with_portfolio] * 100).round(1)}%"
          puts "   Action: Replace correlated position"
          
          # Replace the weaker performing stock in the correlated pair
          weaker_symbol = identify_weaker_performer(risk[:symbols])
          execute_position_replacement(weaker_symbol, candidate[:symbol])
        end
      end,
      priority: 14
    )
    
    # Rule 4: Momentum-Based Rotation
    momentum_rotation_rule = ReteII::Rule.new(
      "momentum_rotation",
      conditions: [
        ReteII::Condition.new(:sector_momentum, {
          sector: ->(s) { s && s.length > 0 },
          momentum_trend: "declining",
          momentum_score: ->(m) { m && m < 0.3 }, # Weak momentum
          duration_days: ->(d) { d && d > 20 } # Trend persisting
        }),
        ReteII::Condition.new(:sector_momentum, {
          sector: ->(s) { s && s.length > 0 },
          momentum_trend: "rising",
          momentum_score: ->(m) { m && m > 0.8 } # Strong momentum
        })
      ],
      action: lambda do |facts, bindings|
        declining = facts.find { |f| f.type == :sector_momentum && f[:momentum_trend] == "declining" }
        rising = facts.find { |f| f.type == :sector_momentum && f[:momentum_trend] == "rising" }
        
        if declining && rising && declining[:sector] != rising[:sector]
          puts "🔀 MOMENTUM ROTATION"
          puts "   From: #{declining[:sector]} (momentum: #{declining[:momentum_score].round(2)})"
          puts "   To: #{rising[:sector]} (momentum: #{rising[:momentum_score].round(2)})"
          puts "   Action: Rotate allocation between sectors"
          
          execute_sector_rotation(declining[:sector], rising[:sector], 0.10) # 10% rotation
        end
      end,
      priority: 10
    )
    
    # Rule 5: Quality Score Replacement
    quality_replacement_rule = ReteII::Rule.new(
      "quality_score_replacement",
      conditions: [
        ReteII::Condition.new(:position_quality, {
          symbol: ->(s) { s && s.length > 0 },
          quality_score: ->(q) { q && q < 0.4 }, # Low quality score
          sector: ->(s) { s && s.length > 0 }
        }),
        ReteII::Condition.new(:replacement_candidate, {
          quality_score: ->(q) { q && q > 0.8 }, # High quality score
          sector: ->(s) { s && s.length > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        low_quality = facts.find { |f| f.type == :position_quality }
        high_quality = facts.find { |f| f.type == :replacement_candidate }
        
        if low_quality[:sector] == high_quality[:sector]
          puts "⭐ QUALITY UPGRADE: #{low_quality[:symbol]} → #{high_quality[:symbol]}"
          puts "   Current Quality: #{low_quality[:quality_score].round(2)}"
          puts "   Replacement Quality: #{high_quality[:quality_score].round(2)}"
          puts "   Sector: #{low_quality[:sector]}"
          
          execute_position_replacement(low_quality[:symbol], high_quality[:symbol])
        end
      end,
      priority: 8
    )
    
    # Rule 6: Risk-Adjusted Return Optimization
    risk_adjusted_optimization_rule = ReteII::Rule.new(
      "risk_adjusted_optimization",
      conditions: [
        ReteII::Condition.new(:position_metrics, {
          symbol: ->(s) { s && s.length > 0 },
          sharpe_ratio: ->(sr) { sr && sr < 0.5 }, # Low risk-adjusted return
          volatility: ->(v) { v && v > 0.3 } # High volatility
        }),
        ReteII::Condition.new(:replacement_candidate, {
          sharpe_ratio: ->(sr) { sr && sr > 1.0 }, # Better risk-adjusted return
          volatility: ->(v) { v && v < 0.2 } # Lower volatility
        })
      ],
      action: lambda do |facts, bindings|
        poor_performer = facts.find { |f| f.type == :position_metrics }
        better_candidate = facts.find { |f| f.type == :replacement_candidate }
        
        puts "📈 RISK-ADJUSTED OPTIMIZATION"
        puts "   Replace: #{poor_performer[:symbol]}"
        puts "     Sharpe Ratio: #{poor_performer[:sharpe_ratio].round(2)}"
        puts "     Volatility: #{(poor_performer[:volatility] * 100).round(1)}%"
        puts "   With: #{better_candidate[:symbol]}"
        puts "     Sharpe Ratio: #{better_candidate[:sharpe_ratio].round(2)}"
        puts "     Volatility: #{(better_candidate[:volatility] * 100).round(1)}%"
        
        execute_position_replacement(poor_performer[:symbol], better_candidate[:symbol])
      end,
      priority: 11
    )
    
    # Rule 7: Quarterly Rebalancing Trigger
    quarterly_rebalancing_rule = ReteII::Rule.new(
      "quarterly_rebalancing",
      conditions: [
        ReteII::Condition.new(:calendar_event, {
          event_type: "quarter_end",
          days_since_last_rebalance: ->(d) { d && d > 85 } # >85 days
        }),
        ReteII::Condition.new(:portfolio_metrics, {
          total_drift: ->(d) { d && d > 3 } # >3% total portfolio drift
        })
      ],
      action: lambda do |facts, bindings|
        event = facts.find { |f| f.type == :calendar_event }
        metrics = facts.find { |f| f.type == :portfolio_metrics }
        
        puts "📅 QUARTERLY REBALANCING TRIGGER"
        puts "   Days Since Last Rebalance: #{event[:days_since_last_rebalance]}"
        puts "   Total Portfolio Drift: #{metrics[:total_drift].round(1)}%"
        puts "   Action: Full portfolio rebalancing"
        
        execute_full_portfolio_rebalancing
      end,
      priority: 16
    )
    
    @engine.add_rule(allocation_drift_rule)
    @engine.add_rule(underperformer_replacement_rule)
    @engine.add_rule(correlation_replacement_rule)
    @engine.add_rule(momentum_rotation_rule)
    @engine.add_rule(quality_replacement_rule)
    @engine.add_rule(risk_adjusted_optimization_rule)
    @engine.add_rule(quarterly_rebalancing_rule)
  end
  
  def calculate_sector_allocations
    total_value = calculate_total_portfolio_value
    return {} if total_value <= 0
    
    sector_values = Hash.new(0)
    
    @portfolio[:positions].each do |symbol, position|
      next unless position[:status] == "open"
      sector = @portfolio[:sector_mappings][symbol] || "Unknown"
      current_value = position[:shares] * @current_prices[symbol] if @current_prices[symbol]
      sector_values[sector] += current_value if current_value
    end
    
    sector_allocations = {}
    sector_values.each do |sector, value|
      sector_allocations[sector] = value / total_value.to_f
    end
    
    sector_allocations
  end
  
  def calculate_total_portfolio_value
    total = @portfolio[:cash]
    @portfolio[:positions].each do |symbol, position|
      if position[:status] == "open" && @current_prices[symbol]
        total += position[:shares] * @current_prices[symbol]
      end
    end
    total
  end
  
  def trigger_sector_rebalancing(sector, target_weight, current_weight)
    puts "   🔄 Triggering sector rebalancing for #{sector}"
    
    # Calculate the dollar amount to adjust
    total_value = calculate_total_portfolio_value
    target_value = total_value * target_weight
    current_value = total_value * current_weight
    adjustment_needed = target_value - current_value
    
    puts "   💰 Adjustment needed: $#{adjustment_needed.round(2)}"
    
    if adjustment_needed > 0
      # Need to buy more of this sector
      buy_sector_positions(sector, adjustment_needed)
    else
      # Need to sell some of this sector
      sell_sector_positions(sector, adjustment_needed.abs)
    end
  end
  
  def execute_position_replacement(old_symbol, new_symbol)
    old_position = @portfolio[:positions][old_symbol]
    return unless old_position && old_position[:status] == "open"
    
    old_price = @current_prices[old_symbol]
    new_price = @current_prices[new_symbol]
    return unless old_price && new_price
    
    # Sell old position
    proceeds = old_position[:shares] * old_price
    @portfolio[:cash] += proceeds
    old_position[:status] = "closed"
    old_position[:exit_price] = old_price
    
    # Buy new position with proceeds
    new_shares = (proceeds / new_price).to_i
    if new_shares > 0
      cost = new_shares * new_price
      @portfolio[:cash] -= cost
      
      @portfolio[:positions][new_symbol] = {
        symbol: new_symbol,
        shares: new_shares,
        entry_price: new_price,
        status: "open"
      }
      
      puts "   ✅ REPLACEMENT EXECUTED:"
      puts "     Sold: #{old_position[:shares]} shares of #{old_symbol} at $#{old_price}"
      puts "     Bought: #{new_shares} shares of #{new_symbol} at $#{new_price}"
      puts "     Cash: $#{@portfolio[:cash].round(2)}"
    end
  end
  
  def execute_sector_rotation(from_sector, to_sector, rotation_percentage)
    total_value = calculate_total_portfolio_value
    rotation_amount = total_value * rotation_percentage
    
    puts "   🔀 Rotating $#{rotation_amount.round(2)} from #{from_sector} to #{to_sector}"
    
    # Sell positions from declining sector
    sell_sector_positions(from_sector, rotation_amount)
    
    # Buy positions in rising sector
    buy_sector_positions(to_sector, rotation_amount)
  end
  
  def execute_full_portfolio_rebalancing
    puts "   🔄 Executing full portfolio rebalancing"
    
    current_allocations = calculate_sector_allocations
    total_value = calculate_total_portfolio_value
    
    @portfolio[:target_allocations].each do |sector, target_weight|
      current_weight = current_allocations[sector] || 0
      drift = ((current_weight - target_weight) / target_weight * 100) rescue 0
      
      if drift.abs > 2 # Rebalance if >2% drift
        adjustment = total_value * (target_weight - current_weight)
        
        if adjustment > 0
          buy_sector_positions(sector, adjustment)
        else
          sell_sector_positions(sector, adjustment.abs)
        end
      end
    end
    
    @portfolio[:rebalancing_history] << {
      date: Date.today,
      type: "full_rebalancing",
      allocations_before: current_allocations.dup,
      allocations_after: calculate_sector_allocations
    }
  end
  
  def buy_sector_positions(sector, amount)
    candidates = @portfolio[:replacement_candidates][sector] || []
    return if candidates.empty? || amount <= 0
    
    # Simple equal-weight allocation among candidates
    amount_per_stock = amount / candidates.length
    
    candidates.each do |symbol|
      price = @current_prices[symbol]
      next unless price
      
      shares = (amount_per_stock / price).to_i
      next if shares <= 0
      
      cost = shares * price
      if @portfolio[:cash] >= cost
        @portfolio[:cash] -= cost
        
        if @portfolio[:positions][symbol] && @portfolio[:positions][symbol][:status] == "open"
          # Add to existing position
          existing = @portfolio[:positions][symbol]
          total_shares = existing[:shares] + shares
          total_cost = (existing[:shares] * existing[:entry_price]) + cost
          
          existing[:shares] = total_shares
          existing[:entry_price] = total_cost / total_shares
        else
          # Create new position
          @portfolio[:positions][symbol] = {
            symbol: symbol,
            shares: shares,
            entry_price: price,
            status: "open"
          }
        end
        
        puts "     ✅ Bought #{shares} shares of #{symbol} at $#{price}"
      end
    end
  end
  
  def sell_sector_positions(sector, amount)
    sector_positions = @portfolio[:positions].select do |symbol, position|
      position[:status] == "open" && @portfolio[:sector_mappings][symbol] == sector
    end
    
    return if sector_positions.empty? || amount <= 0
    
    # Sell proportionally from sector positions
    total_sector_value = sector_positions.sum do |symbol, position|
      position[:shares] * @current_prices[symbol] if @current_prices[symbol]
    end.compact.sum
    
    return if total_sector_value <= 0
    
    sector_positions.each do |symbol, position|
      position_value = position[:shares] * @current_prices[symbol]
      proportion = position_value / total_sector_value
      shares_to_sell = ((amount * proportion) / @current_prices[symbol]).to_i
      
      if shares_to_sell > 0 && shares_to_sell <= position[:shares]
        proceeds = shares_to_sell * @current_prices[symbol]
        @portfolio[:cash] += proceeds
        
        position[:shares] -= shares_to_sell
        if position[:shares] <= 0
          position[:status] = "closed"
          position[:exit_price] = @current_prices[symbol]
        end
        
        puts "     ✅ Sold #{shares_to_sell} shares of #{symbol} at $#{@current_prices[symbol]}"
      end
    end
  end
  
  def identify_weaker_performer(symbols)
    performances = symbols.map do |symbol|
      position = @portfolio[:positions][symbol]
      if position && position[:status] == "open" && @current_prices[symbol]
        current_value = position[:shares] * @current_prices[symbol]
        entry_value = position[:shares] * position[:entry_price]
        performance = ((current_value - entry_value) / entry_value) * 100
        [symbol, performance]
      end
    end.compact
    
    # Return the symbol with the worst performance
    performances.min_by { |symbol, perf| perf }&.first || symbols.first
  end
  
  def simulate_rebalancing_scenarios
    puts "🔄 PORTFOLIO REBALANCING SYSTEM DEMONSTRATION"
    puts "=" * 70
    
    # Initialize some positions
    @current_prices = {
      "AAPL" => 185.50, "GOOGL" => 161.90, "MSFT" => 320.00, "NVDA" => 425.80,
      "TSLA" => 238.90, "META" => 298.50, "JNJ" => 165.20, "PFE" => 35.80,
      "JPM" => 145.60, "BAC" => 28.90
    }
    
    # Create initial portfolio
    initial_positions = {
      "AAPL" => { symbol: "AAPL", shares: 200, entry_price: 180.00, status: "open" },
      "GOOGL" => { symbol: "GOOGL", shares: 150, entry_price: 160.00, status: "open" },
      "TSLA" => { symbol: "TSLA", shares: 100, entry_price: 240.00, status: "open" },
      "JNJ" => { symbol: "JNJ", shares: 80, entry_price: 170.00, status: "open" }
    }
    @portfolio[:positions] = initial_positions
    @portfolio[:cash] = 25_000
    
    puts "\n📊 Initial Portfolio:"
    print_portfolio_status
    
    # Scenario 1: Allocation Drift
    puts "\n🎯 SCENARIO 1: Sector Allocation Drift"
    puts "-" * 50
    @engine.working_memory.facts.clear
    
    allocations = calculate_sector_allocations
    allocations.each do |sector, current_weight|
      target_weight = @portfolio[:target_allocations][sector] || 0
      drift = ((current_weight - target_weight) / target_weight * 100) rescue 0
      
      if drift.abs > 5
        @engine.add_fact(:portfolio_allocation, {
          sector: sector,
          current_weight: current_weight,
          target_weight: target_weight,
          drift_percentage: drift
        })
      end
    end
    @engine.run
    
    # Scenario 2: Underperformer Replacement
    puts "\n🎯 SCENARIO 2: Underperformer Replacement"
    puts "-" * 50
    @engine.working_memory.facts.clear
    
    @engine.add_fact(:position_performance, {
      symbol: "TSLA",
      relative_performance: -15.2,
      days_held: 45,
      sector: "Consumer"
    })
    
    @engine.add_fact(:replacement_candidate, {
      symbol: "AMZN",
      sector: "Consumer", 
      relative_performance: 8.3,
      momentum_score: 0.85
    })
    @engine.run
    
    # Scenario 3: Correlation Risk
    puts "\n🎯 SCENARIO 3: Correlation Risk Reduction"
    puts "-" * 50
    @engine.working_memory.facts.clear
    
    @engine.add_fact(:correlation_risk, {
      symbols: ["AAPL", "GOOGL"],
      correlation_coefficient: 0.87,
      combined_allocation: 0.32,
      sector: "Technology"
    })
    
    @engine.add_fact(:replacement_candidate, {
      symbol: "MSFT",
      sector: "Technology",
      correlation_with_portfolio: 0.42
    })
    @engine.run
    
    # Scenario 4: Momentum Rotation
    puts "\n🎯 SCENARIO 4: Momentum-Based Rotation"
    puts "-" * 50
    @engine.working_memory.facts.clear
    
    @engine.add_fact(:sector_momentum, {
      sector: "Technology",
      momentum_trend: "declining",
      momentum_score: 0.25,
      duration_days: 25
    })
    
    @engine.add_fact(:sector_momentum, {
      sector: "Healthcare", 
      momentum_trend: "rising",
      momentum_score: 0.85
    })
    @engine.run
    
    # Scenario 5: Quality Replacement
    puts "\n🎯 SCENARIO 5: Quality Score Replacement"
    puts "-" * 50
    @engine.working_memory.facts.clear
    
    @engine.add_fact(:position_quality, {
      symbol: "TSLA",
      quality_score: 0.35,
      sector: "Consumer"
    })
    
    @engine.add_fact(:replacement_candidate, {
      symbol: "AMZN",
      quality_score: 0.88,
      sector: "Consumer"
    })
    @engine.run
    
    puts "\n📊 Final Portfolio:"
    print_portfolio_status
    
    puts "\n" + "=" * 70
    puts "REBALANCING DEMONSTRATION COMPLETE"
  end
  
  def print_portfolio_status
    total_value = calculate_total_portfolio_value
    allocations = calculate_sector_allocations
    
    puts "Total Portfolio Value: $#{total_value.round(2)}"
    puts "Cash: $#{@portfolio[:cash].round(2)}"
    puts ""
    puts "Sector Allocations:"
    
    @portfolio[:target_allocations].each do |sector, target|
      current = allocations[sector] || 0
      drift = ((current - target) / target * 100) rescue 0
      
      puts "  #{sector}:"
      puts "    Current: #{(current * 100).round(1)}% (Target: #{(target * 100).round(1)}%)"
      puts "    Drift: #{drift > 0 ? '+' : ''}#{drift.round(1)}%"
    end
    
    puts ""
    puts "Positions:"
    @portfolio[:positions].each do |symbol, position|
      if position[:status] == "open" && @current_prices[symbol]
        current_value = position[:shares] * @current_prices[symbol]
        pnl = current_value - (position[:shares] * position[:entry_price])
        pnl_pct = (pnl / (position[:shares] * position[:entry_price]) * 100)
        
        puts "  #{symbol}: #{position[:shares]} shares @ $#{@current_prices[symbol]} = $#{current_value.round(2)} (#{pnl_pct > 0 ? '+' : ''}#{pnl_pct.round(1)}%)"
      end
    end
  end
end

if __FILE__ == $0
  system = PortfolioRebalancingSystem.new
  system.simulate_rebalancing_scenarios
end