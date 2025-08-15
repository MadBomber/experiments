#!/usr/bin/env ruby

require_relative '../rete2'

class StockTradingExpertSystem
  def initialize
    @engine = ReteII::ReteEngine.new
    setup_rules
  end
  
  def setup_rules
    bull_market_rule = ReteII::Rule.new(
      "bull_market_buy",
      conditions: [
        ReteII::Condition.new(:market, { trend: "bullish" }),
        ReteII::Condition.new(:stock, { 
          rsi: ->(rsi) { rsi < 70 }
        }),
        ReteII::Condition.new(:stock, {
          pe_ratio: ->(pe) { pe < 25 }
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "📈 BUY SIGNAL: #{stock[:symbol]} - Bull market with good fundamentals"
        puts "   RSI: #{stock[:rsi]}, P/E: #{stock[:pe_ratio]}"
      end,
      priority: 10
    )
    
    oversold_bounce_rule = ReteII::Rule.new(
      "oversold_bounce",
      conditions: [
        ReteII::Condition.new(:stock, {
          rsi: ->(rsi) { rsi < 30 }
        }),
        ReteII::Condition.new(:stock, {
          volume: ->(v) { v > 1000000 }
        }),
        ReteII::Condition.new(:news, { sentiment: "negative" }, negated: true)
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🔄 OVERSOLD BOUNCE: #{stock[:symbol]} - Potential reversal opportunity"
        puts "   RSI: #{stock[:rsi]}, Volume: #{stock[:volume]}"
      end,
      priority: 8
    )
    
    stop_loss_rule = ReteII::Rule.new(
      "stop_loss_trigger",
      conditions: [
        ReteII::Condition.new(:position, {
          loss_percent: ->(loss) { loss > 8 }
        }),
        ReteII::Condition.new(:market, { trend: "bearish" })
      ],
      action: lambda do |facts, bindings|
        position = facts.find { |f| f.type == :position }
        puts "🛑 STOP LOSS: #{position[:symbol]} - Exit position immediately"
        puts "   Loss: #{position[:loss_percent]}%"
      end,
      priority: 15
    )
    
    earnings_surprise_rule = ReteII::Rule.new(
      "earnings_surprise",
      conditions: [
        ReteII::Condition.new(:earnings, {
          surprise: ->(s) { s > 10 }
        }),
        ReteII::Condition.new(:stock, {
          momentum: ->(m) { m > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        earnings = facts.find { |f| f.type == :earnings }
        stock = facts.find { |f| f.type == :stock }
        puts "💰 EARNINGS BEAT: #{stock[:symbol]} - Strong earnings surprise"
        puts "   Surprise: #{earnings[:surprise]}%, Momentum: #{stock[:momentum]}"
      end,
      priority: 12
    )
    
    divergence_rule = ReteII::Rule.new(
      "price_volume_divergence",
      conditions: [
        ReteII::Condition.new(:stock, {
          price_trend: "up"
        }),
        ReteII::Condition.new(:stock, {
          volume_trend: "down"
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "⚠️  DIVERGENCE WARNING: #{stock[:symbol]} - Price/volume divergence detected"
      end,
      priority: 5
    )
    
    @engine.add_rule(bull_market_rule)
    @engine.add_rule(oversold_bounce_rule)
    @engine.add_rule(stop_loss_rule)
    @engine.add_rule(earnings_surprise_rule)
    @engine.add_rule(divergence_rule)
  end
  
  def analyze_market(market_conditions)
    puts "\n" + "=" * 70
    puts "MARKET ANALYSIS - #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "=" * 70
    
    market_conditions.each do |condition|
      case condition[:type]
      when :market
        @engine.add_fact(:market, condition[:data])
      when :stock
        @engine.add_fact(:stock, condition[:data])
      when :position
        @engine.add_fact(:position, condition[:data])
      when :earnings
        @engine.add_fact(:earnings, condition[:data])
      when :news
        @engine.add_fact(:news, condition[:data])
      end
    end
    
    @engine.run
    puts "=" * 70
  end
  
  def clear_facts
    @engine.working_memory.facts.clear
  end
end

class NetworkDiagnosticSystem
  def initialize
    @engine = ReteII::ReteEngine.new
    setup_network_rules
  end
  
  def setup_network_rules
    ddos_attack_rule = ReteII::Rule.new(
      "ddos_detection",
      conditions: [
        ReteII::Condition.new(:traffic, {
          requests_per_second: ->(rps) { rps > 10000 }
        }),
        ReteII::Condition.new(:traffic, {
          unique_ips: ->(ips) { ips < 100 }
        }),
        ReteII::Condition.new(:firewall, { status: "active" }, negated: true)
      ],
      action: lambda do |facts, bindings|
        traffic = facts.find { |f| f.type == :traffic }
        puts "🚨 DDoS ATTACK DETECTED!"
        puts "   Requests/sec: #{traffic[:requests_per_second]}"
        puts "   Unique IPs: #{traffic[:unique_ips]}"
        puts "   ACTION: Enabling rate limiting and firewall rules"
      end
    )
    
    bandwidth_issue_rule = ReteII::Rule.new(
      "bandwidth_saturation",
      conditions: [
        ReteII::Condition.new(:network, {
          bandwidth_usage: ->(usage) { usage > 90 }
        }),
        ReteII::Condition.new(:service, { priority: "high" })
      ],
      action: lambda do |facts, bindings|
        network = facts.find { |f| f.type == :network }
        service = facts.find { |f| f.type == :service }
        puts "⚠️  BANDWIDTH SATURATION: #{network[:bandwidth_usage]}% utilized"
        puts "   High priority service affected: #{service[:name]}"
        puts "   ACTION: Implementing QoS policies"
      end
    )
    
    latency_spike_rule = ReteII::Rule.new(
      "latency_anomaly",
      conditions: [
        ReteII::Condition.new(:latency, {
          current_ms: ->(ms) { ms > 200 }
        }),
        ReteII::Condition.new(:latency, {
          baseline_ms: ->(ms) { ms < 50 }
        })
      ],
      action: lambda do |facts, bindings|
        latency = facts.find { |f| f.type == :latency }
        puts "🔧 LATENCY SPIKE DETECTED"
        puts "   Current: #{latency[:current_ms]}ms (baseline: #{latency[:baseline_ms]}ms)"
        puts "   ACTION: Rerouting traffic to alternate path"
      end
    )
    
    @engine.add_rule(ddos_attack_rule)
    @engine.add_rule(bandwidth_issue_rule)
    @engine.add_rule(latency_spike_rule)
  end
  
  def diagnose(conditions)
    puts "\n" + "=" * 70
    puts "NETWORK DIAGNOSTIC REPORT - #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "=" * 70
    
    conditions.each do |condition|
      @engine.add_fact(condition[:type], condition[:data])
    end
    
    @engine.run
    puts "=" * 70
  end
end

if __FILE__ == $0
  puts "\n🏦 STOCK TRADING EXPERT SYSTEM DEMONSTRATION"
  puts "=" * 70
  
  trading_system = StockTradingExpertSystem.new
  
  scenario1 = [
    { type: :market, data: { trend: "bullish", volatility: "low" } },
    { type: :stock, data: { symbol: "AAPL", rsi: 45, pe_ratio: 22, momentum: 5 } },
    { type: :stock, data: { symbol: "GOOGL", rsi: 28, volume: 2000000, momentum: -2 } }
  ]
  
  trading_system.analyze_market(scenario1)
  trading_system.clear_facts
  
  scenario2 = [
    { type: :market, data: { trend: "bearish", volatility: "high" } },
    { type: :position, data: { symbol: "TSLA", loss_percent: 12, shares: 100 } },
    { type: :earnings, data: { symbol: "MSFT", surprise: 15, quarter: "Q4" } },
    { type: :stock, data: { symbol: "MSFT", momentum: 8, rsi: 62 } }
  ]
  
  trading_system.analyze_market(scenario2)
  trading_system.clear_facts
  
  scenario3 = [
    { type: :stock, data: { symbol: "META", price_trend: "up", volume_trend: "down" } },
    { type: :stock, data: { symbol: "NVDA", rsi: 25, volume: 5000000, momentum: 3 } }
  ]
  
  trading_system.analyze_market(scenario3)
  
  puts "\n\n🌐 NETWORK DIAGNOSTIC SYSTEM DEMONSTRATION"
  puts "=" * 70
  
  network_system = NetworkDiagnosticSystem.new
  
  network_scenario1 = [
    { type: :traffic, data: { requests_per_second: 15000, unique_ips: 50, protocol: "HTTP" } },
    { type: :network, data: { bandwidth_usage: 95, packet_loss: 2 } },
    { type: :service, data: { name: "API Gateway", priority: "high" } }
  ]
  
  network_system.diagnose(network_scenario1)
  
  network_scenario2 = [
    { type: :latency, data: { current_ms: 250, baseline_ms: 30, endpoint: "database" } },
    { type: :network, data: { bandwidth_usage: 60, packet_loss: 0 } }
  ]
  
  network_system.diagnose(network_scenario2)
end