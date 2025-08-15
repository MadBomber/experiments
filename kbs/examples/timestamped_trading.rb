#!/usr/bin/env ruby

require_relative '../rete2'
require 'time'

class TimestampedTradingSystem
  def initialize
    @engine = ReteII::ReteEngine.new
    @market_open = Time.parse("09:30:00")
    @market_close = Time.parse("16:00:00")
    setup_time_aware_rules
  end
  
  def setup_time_aware_rules
    # Rule 1: Fresh data only
    fresh_momentum_rule = ReteII::Rule.new(
      "fresh_momentum",
      conditions: [
        ReteII::Condition.new(:stock, {
          price_change: ->(p) { p && p > 2 },
          timestamp: ->(t) { t && (Time.now - t) < 60 }, # Within 1 minute
          market_session: "regular"
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        age = Time.now - stock[:timestamp]
        puts "🚀 FRESH MOMENTUM: #{stock[:symbol]}"
        puts "   Price Change: +#{stock[:price_change]}%"
        puts "   Data Age: #{age.round(1)} seconds"
        puts "   Market Time: #{stock[:market_time]}"
        puts "   Recommendation: BUY (fresh signal)"
      end,
      priority: 15
    )
    
    # Rule 2: Stale data warning
    stale_data_rule = ReteII::Rule.new(
      "stale_data_warning",
      conditions: [
        ReteII::Condition.new(:stock, {
          timestamp: ->(t) { t && (Time.now - t) > 300 } # Older than 5 minutes
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        age = Time.now - stock[:timestamp]
        puts "⚠️  STALE DATA: #{stock[:symbol]}"
        puts "   Data Age: #{(age / 60).round(1)} minutes"
        puts "   Last Update: #{stock[:timestamp]}"
        puts "   ACTION: IGNORE - Data too old"
      end,
      priority: 20
    )
    
    # Rule 3: Market hours validation
    market_hours_rule = ReteII::Rule.new(
      "market_hours_check",
      conditions: [
        ReteII::Condition.new(:stock, {
          market_session: "after_hours",
          volume: ->(v) { v && v > 100_000 }
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🌙 AFTER HOURS ACTIVITY: #{stock[:symbol]}"
        puts "   Volume: #{format_volume(stock[:volume])}"
        puts "   Time: #{stock[:market_time]}"
        puts "   ACTION: Monitor for gap potential"
      end
    )
    
    # Rule 4: Rapid price movement detection
    rapid_movement_rule = ReteII::Rule.new(
      "rapid_movement",
      conditions: [
        ReteII::Condition.new(:price_tick, {
          time_delta: ->(d) { d && d < 5 }, # Within 5 seconds
          price_delta: ->(d) { d && d.abs > 0.50 } # More than $0.50 move
        })
      ],
      action: lambda do |facts, bindings|
        tick = facts.find { |f| f.type == :price_tick }
        direction = tick[:price_delta] > 0 ? "📈 UP" : "📉 DOWN"
        puts "⚡ RAPID MOVEMENT: #{tick[:symbol]} #{direction}"
        puts "   Price Change: #{tick[:price_delta] > 0 ? '+' : ''}$#{tick[:price_delta]}"
        puts "   Time Frame: #{tick[:time_delta]} seconds"
        puts "   ACTION: Check for news catalyst"
      end
    )
    
    # Rule 5: Time-based strategy
    opening_gap_rule = ReteII::Rule.new(
      "opening_gap",
      conditions: [
        ReteII::Condition.new(:stock, {
          market_time: ->(t) { 
            t && (t.hour == 9 && t.min >= 30 && t.min <= 35) # First 5 minutes
          },
          gap_percentage: ->(g) { g && g.abs > 1 }
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        direction = stock[:gap_percentage] > 0 ? "GAP UP" : "GAP DOWN"
        puts "🔔 OPENING #{direction}: #{stock[:symbol]}"
        puts "   Gap: #{stock[:gap_percentage] > 0 ? '+' : ''}#{stock[:gap_percentage]}%"
        puts "   Time: #{stock[:market_time]}"
        puts "   Volume: #{format_volume(stock[:volume])}"
        puts "   ACTION: Monitor for gap fill or continuation"
      end
    )
    
    # Rule 6: End of day positioning
    eod_rule = ReteII::Rule.new(
      "end_of_day",
      conditions: [
        ReteII::Condition.new(:stock, {
          market_time: ->(t) { 
            t && (t.hour == 15 && t.min >= 45) # Last 15 minutes
          }
        }),
        ReteII::Condition.new(:position, { status: "open" })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        position = facts.find { |f| f.type == :position }
        puts "🕐 END OF DAY: #{position[:symbol]}"
        puts "   Current Time: #{stock[:market_time]}"
        puts "   Position P&L: #{position[:unrealized_pnl]}"
        puts "   ACTION: Consider closing before market close"
      end
    )
    
    @engine.add_rule(fresh_momentum_rule)
    @engine.add_rule(stale_data_rule)
    @engine.add_rule(market_hours_rule)
    @engine.add_rule(rapid_movement_rule)
    @engine.add_rule(opening_gap_rule)
    @engine.add_rule(eod_rule)
  end
  
  def format_volume(volume)
    if volume >= 1_000_000
      "#{(volume / 1_000_000.0).round(1)}M"
    elsif volume >= 1_000
      "#{(volume / 1_000.0).round(1)}K"
    else
      volume.to_s
    end
  end
  
  def determine_market_session(time)
    hour_min = time.hour * 100 + time.min
    
    case hour_min
    when 400..929 then "pre_market"
    when 930..1559 then "regular"
    when 1600..2000 then "after_hours"
    else "closed"
    end
  end
  
  def add_timestamped_stock_fact(symbol, price, volume, options = {})
    timestamp = options[:timestamp] || Time.now
    market_time = options[:market_time] || timestamp
    
    @engine.add_fact(:stock, {
      symbol: symbol,
      price: price,
      volume: volume,
      timestamp: timestamp,
      market_time: market_time,
      market_session: determine_market_session(market_time),
      price_change: options[:price_change] || 0,
      gap_percentage: options[:gap_percentage] || 0
    })
  end
  
  def add_price_tick(symbol, old_price, new_price, old_time, new_time)
    price_delta = new_price - old_price
    time_delta = new_time - old_time
    
    @engine.add_fact(:price_tick, {
      symbol: symbol,
      old_price: old_price,
      new_price: new_price,
      price_delta: price_delta,
      time_delta: time_delta,
      timestamp: new_time
    })
  end
  
  def simulate_trading_day
    puts "🏦 TIMESTAMPED STOCK TRADING SYSTEM"
    puts "=" * 60
    
    base_time = Time.parse("2024-08-15 09:30:00")
    
    # Scenario 1: Market Open with Gap
    puts "\n📊 SCENARIO 1: Market Open Gap Up"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    add_timestamped_stock_fact("AAPL", 185.50, 2_500_000, {
      market_time: base_time + 2*60, # 9:32 AM
      price_change: 2.1,
      gap_percentage: 2.3
    })
    @engine.run
    
    # Scenario 2: Fresh Momentum Signal
    puts "\n📊 SCENARIO 2: Fresh Momentum (Recent Data)"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    add_timestamped_stock_fact("GOOGL", 142.80, 1_200_000, {
      timestamp: Time.now - 30, # 30 seconds ago
      market_time: Time.now - 30,
      price_change: 3.2
    })
    @engine.run
    
    # Scenario 3: Stale Data
    puts "\n📊 SCENARIO 3: Stale Data Warning"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    add_timestamped_stock_fact("TSLA", 195.40, 800_000, {
      timestamp: Time.now - 600, # 10 minutes ago
      market_time: Time.now - 600,
      price_change: 1.5
    })
    @engine.run
    
    # Scenario 4: After Hours Activity
    puts "\n📊 SCENARIO 4: After Hours Trading"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    after_hours_time = Time.parse("2024-08-15 17:30:00")
    add_timestamped_stock_fact("NVDA", 425.80, 150_000, {
      market_time: after_hours_time,
      timestamp: after_hours_time
    })
    @engine.run
    
    # Scenario 5: Rapid Price Movement
    puts "\n📊 SCENARIO 5: Rapid Price Tick"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    tick_time = Time.now
    add_price_tick("META", 298.50, 299.25, tick_time - 3, tick_time)
    @engine.run
    
    # Scenario 6: End of Day
    puts "\n📊 SCENARIO 6: End of Trading Day"
    puts "-" * 40
    @engine.working_memory.facts.clear
    
    eod_time = Time.parse("2024-08-15 15:50:00")
    add_timestamped_stock_fact("AMZN", 142.30, 900_000, {
      market_time: eod_time,
      timestamp: eod_time
    })
    
    @engine.add_fact(:position, {
      symbol: "AMZN",
      status: "open",
      shares: 100,
      entry_price: 140.00,
      unrealized_pnl: 230.00
    })
    @engine.run
    
    puts "\n" + "=" * 60
    puts "TIMESTAMPED TRADING SIMULATION COMPLETE"
  end
end

if __FILE__ == $0
  system = TimestampedTradingSystem.new
  system.simulate_trading_day
end