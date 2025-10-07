#!/usr/bin/env ruby

require_relative '../rete2'

class WorkingTradingDemo
  def initialize
    @engine = ReteII::ReteEngine.new
    setup_simple_rules
  end
  
  def setup_simple_rules
    # Rule 1: Simple stock momentum
    momentum_rule = ReteII::Rule.new(
      "momentum_buy",
      conditions: [
        ReteII::Condition.new(:stock, { symbol: "AAPL" })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🚀 MOMENTUM SIGNAL: #{stock[:symbol]}"
        puts "   Price: $#{stock[:price]}"
        puts "   Volume: #{stock[:volume].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
        puts "   Recommendation: BUY"
      end
    )
    
    # Rule 2: High volume alert
    volume_rule = ReteII::Rule.new(
      "high_volume",
      conditions: [
        ReteII::Condition.new(:stock, { volume: ->(v) { v && v > 1000000 } })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "📊 HIGH VOLUME ALERT: #{stock[:symbol]}"
        puts "   Volume: #{stock[:volume].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
        puts "   Above 1M shares traded"
      end
    )
    
    # Rule 3: Price movement
    price_rule = ReteII::Rule.new(
      "price_movement",
      conditions: [
        ReteII::Condition.new(:stock, { price_change: ->(p) { p && p.abs > 2 } })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        direction = stock[:price_change] > 0 ? "UP" : "DOWN"
        puts "📈 SIGNIFICANT MOVE: #{stock[:symbol]} #{direction}"
        puts "   Change: #{stock[:price_change] > 0 ? '+' : ''}#{stock[:price_change]}%"
      end
    )
    
    # Rule 4: RSI signals
    rsi_rule = ReteII::Rule.new(
      "rsi_signal",
      conditions: [
        ReteII::Condition.new(:stock, { rsi: ->(r) { r && (r < 30 || r > 70) } })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        condition = stock[:rsi] < 30 ? "OVERSOLD" : "OVERBOUGHT"
        action = stock[:rsi] < 30 ? "BUY" : "SELL"
        puts "⚡ RSI SIGNAL: #{stock[:symbol]} #{condition}"
        puts "   RSI: #{stock[:rsi].round(1)}"
        puts "   Recommendation: #{action}"
      end
    )
    
    # Rule 5: Multi-condition golden cross
    golden_cross_rule = ReteII::Rule.new(
      "golden_cross_complete",
      conditions: [
        ReteII::Condition.new(:stock, { symbol: "AAPL" }),
        ReteII::Condition.new(:ma_signal, { type: "golden_cross" })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        signal = facts.find { |f| f.type == :ma_signal }
        puts "🌟 GOLDEN CROSS CONFIRMED: #{stock[:symbol]}"
        puts "   50-day MA crossed above 200-day MA"
        puts "   Price: $#{stock[:price]}"
        puts "   Recommendation: STRONG BUY"
      end
    )
    
    @engine.add_rule(momentum_rule)
    @engine.add_rule(volume_rule)
    @engine.add_rule(price_rule)
    @engine.add_rule(rsi_rule)
    @engine.add_rule(golden_cross_rule)
  end
  
  def run_scenarios
    puts "🏦 STOCK TRADING EXPERT SYSTEM"
    puts "=" * 50
    
    # Scenario 1: Apple momentum
    puts "\n📊 SCENARIO 1: Apple with High Volume"
    puts "-" * 30
    @engine.working_memory.facts.clear
    @engine.add_fact(:stock, {
      symbol: "AAPL",
      price: 185.50,
      volume: 1_500_000,
      price_change: 3.2,
      rsi: 68
    })
    @engine.run
    
    # Scenario 2: Google big move
    puts "\n📊 SCENARIO 2: Google Big Price Move"
    puts "-" * 30
    @engine.working_memory.facts.clear
    @engine.add_fact(:stock, {
      symbol: "GOOGL",
      price: 142.80,
      volume: 800_000,
      price_change: -4.1,
      rsi: 75
    })
    @engine.run
    
    # Scenario 3: Tesla oversold
    puts "\n📊 SCENARIO 3: Tesla Oversold"
    puts "-" * 30
    @engine.working_memory.facts.clear
    @engine.add_fact(:stock, {
      symbol: "TSLA",
      price: 195.40,
      volume: 2_200_000,
      price_change: -1.8,
      rsi: 25
    })
    @engine.run
    
    # Scenario 4: Apple Golden Cross
    puts "\n📊 SCENARIO 4: Apple Golden Cross"
    puts "-" * 30
    @engine.working_memory.facts.clear
    @engine.add_fact(:stock, {
      symbol: "AAPL",
      price: 190.25,
      volume: 1_100_000,
      price_change: 2.1,
      rsi: 55
    })
    @engine.add_fact(:ma_signal, {
      symbol: "AAPL",
      type: "golden_cross"
    })
    @engine.run
    
    # Scenario 5: Multiple signals
    puts "\n📊 SCENARIO 5: NVIDIA Multiple Signals"
    puts "-" * 30
    @engine.working_memory.facts.clear
    @engine.add_fact(:stock, {
      symbol: "NVDA",
      price: 425.80,
      volume: 3_500_000,
      price_change: 8.7,
      rsi: 78
    })
    @engine.run
    
    puts "\n" + "=" * 50
    puts "DEMONSTRATION COMPLETE"
  end
end

if __FILE__ == $0
  demo = WorkingTradingDemo.new
  demo.run_scenarios
end