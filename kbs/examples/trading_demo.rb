#!/usr/bin/env ruby

require_relative '../rete2'

class TradingDemo
  def initialize
    @engine = ReteII::ReteEngine.new
    setup_trading_rules
    puts "🏦 STOCK TRADING EXPERT SYSTEM LOADED"
    puts "📊 #{@engine.rules.size} trading strategies active"
  end
  
  def setup_trading_rules
    golden_cross = ReteII::Rule.new(
      "golden_cross_buy",
      conditions: [
        ReteII::Condition.new(:ma_signal, { type: "golden_cross" }),
        ReteII::Condition.new(:stock, { volume: ->(v) { v && v > 500000 } })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        signal = facts.find { |f| f.type == :ma_signal }
        puts "📈 GOLDEN CROSS SIGNAL: #{stock[:symbol]}"
        puts "   50-MA crossed above 200-MA"
        puts "   Volume: #{format_volume(stock[:volume])}"
        puts "   Price: $#{stock[:price]}"
        puts "   Recommendation: STRONG BUY"
      end
    )
    
    momentum_buy = ReteII::Rule.new(
      "momentum_breakout",
      conditions: [
        ReteII::Condition.new(:stock, { 
          price_change: ->(p) { p > 2 },
          rsi: ->(r) { r.between?(50, 75) }
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🚀 MOMENTUM BREAKOUT: #{stock[:symbol]}"
        puts "   Price Change: +#{stock[:price_change].round(1)}%"
        puts "   RSI: #{stock[:rsi].round(1)} (strong but not overbought)"
        puts "   Recommendation: BUY"
      end
    )
    
    oversold_buy = ReteII::Rule.new(
      "oversold_reversal",
      conditions: [
        ReteII::Condition.new(:stock, { rsi: ->(r) { r < 35 } }),
        ReteII::Condition.new(:market, { trend: "bullish" })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🔄 OVERSOLD REVERSAL: #{stock[:symbol]}"
        puts "   RSI: #{stock[:rsi].round(1)} (oversold)"
        puts "   Market: Bullish environment"
        puts "   Recommendation: CONTRARIAN BUY"
      end
    )
    
    earnings_volatility = ReteII::Rule.new(
      "earnings_play",
      conditions: [
        ReteII::Condition.new(:earnings, { days_until: ->(d) { d <= 3 } }),
        ReteII::Condition.new(:options, { iv: ->(v) { v > 40 } })
      ],
      action: lambda do |facts, bindings|
        earnings = facts.find { |f| f.type == :earnings }
        options = facts.find { |f| f.type == :options }
        puts "💰 EARNINGS PLAY: #{earnings[:symbol]}"
        puts "   Earnings in #{earnings[:days_until]} day(s)"
        puts "   Implied Volatility: #{options[:iv].round(1)}%"
        puts "   Recommendation: VOLATILITY STRATEGY"
      end
    )
    
    stop_loss = ReteII::Rule.new(
      "stop_loss_alert",
      conditions: [
        ReteII::Condition.new(:position, { 
          status: "open",
          loss_pct: ->(l) { l > 8 }
        })
      ],
      action: lambda do |facts, bindings|
        position = facts.find { |f| f.type == :position }
        puts "🛑 STOP LOSS TRIGGERED: #{position[:symbol]}"
        puts "   Loss: #{position[:loss_pct].round(1)}%"
        puts "   Entry: $#{position[:entry_price]}"
        puts "   Current: $#{position[:current_price]}"
        puts "   Recommendation: SELL IMMEDIATELY"
      end
    )
    
    risk_warning = ReteII::Rule.new(
      "concentration_risk",
      conditions: [
        ReteII::Condition.new(:portfolio, { 
          concentration: ->(c) { c > 25 }
        })
      ],
      action: lambda do |facts, bindings|
        portfolio = facts.find { |f| f.type == :portfolio }
        puts "⚠️  CONCENTRATION RISK: #{portfolio[:top_holding]}"
        puts "   Position Size: #{portfolio[:concentration].round(1)}% of portfolio"
        puts "   Recommendation: DIVERSIFY HOLDINGS"
      end
    )
    
    news_catalyst = ReteII::Rule.new(
      "news_sentiment",
      conditions: [
        ReteII::Condition.new(:news, { 
          sentiment: ->(s) { s.abs > 0.6 },
          impact: "high"
        })
      ],
      action: lambda do |facts, bindings|
        news = facts.find { |f| f.type == :news }
        sentiment = news[:sentiment] > 0 ? "POSITIVE" : "NEGATIVE"
        action = news[:sentiment] > 0 ? "BUY" : "SELL"
        puts "📰 NEWS CATALYST: #{news[:symbol]}"
        puts "   Sentiment: #{sentiment} (#{news[:sentiment].round(2)})"
        puts "   Impact: HIGH"
        puts "   Recommendation: #{action} ON NEWS"
      end
    )
    
    sector_rotation = ReteII::Rule.new(
      "sector_strength",
      conditions: [
        ReteII::Condition.new(:sector, { 
          performance: ->(p) { p > 5 },
          trend: "accelerating"
        })
      ],
      action: lambda do |facts, bindings|
        sector = facts.find { |f| f.type == :sector }
        puts "🔄 SECTOR ROTATION: #{sector[:name]}"
        puts "   Performance: +#{sector[:performance].round(1)}%"
        puts "   Trend: Accelerating"
        puts "   Recommendation: INCREASE ALLOCATION"
      end
    )
    
    @engine.add_rule(golden_cross)
    @engine.add_rule(momentum_buy)
    @engine.add_rule(oversold_buy)
    @engine.add_rule(earnings_volatility)
    @engine.add_rule(stop_loss)
    @engine.add_rule(risk_warning)
    @engine.add_rule(news_catalyst)
    @engine.add_rule(sector_rotation)
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
  
  def generate_scenario(name, &block)
    puts "\n" + "="*60
    puts "SCENARIO: #{name}"
    puts "="*60
    
    @engine.working_memory.facts.clear
    
    yield
    
    puts "\nFacts in working memory:"
    @engine.working_memory.facts.each do |fact|
      puts "  #{fact}"
    end
    puts ""
    
    @engine.run
    
    puts "-"*60
  end
  
  def demo_scenarios
    generate_scenario("Bull Market with Golden Cross") do
      @engine.add_fact(:stock, {
        symbol: "AAPL",
        price: 185.50,
        volume: 1_250_000,
        price_change: 1.2,
        rsi: 65
      })
      
      @engine.add_fact(:ma_signal, {
        symbol: "AAPL",
        type: "golden_cross"
      })
      
      @engine.add_fact(:market, { trend: "bullish" })
    end
    
    generate_scenario("Momentum Breakout") do
      @engine.add_fact(:stock, {
        symbol: "NVDA",
        price: 425.80,
        volume: 980_000,
        price_change: 4.7,
        rsi: 68
      })
      
      @engine.add_fact(:market, { trend: "bullish" })
    end
    
    generate_scenario("Oversold Bounce Opportunity") do
      @engine.add_fact(:stock, {
        symbol: "TSLA",
        price: 178.90,
        volume: 750_000,
        price_change: -2.1,
        rsi: 28
      })
      
      @engine.add_fact(:market, { trend: "bullish" })
    end
    
    generate_scenario("Earnings Volatility Play") do
      @engine.add_fact(:earnings, {
        symbol: "GOOGL",
        days_until: 2,
        expected_move: 8.5
      })
      
      @engine.add_fact(:options, {
        symbol: "GOOGL",
        iv: 45.2,
        iv_rank: 75
      })
    end
    
    generate_scenario("Stop Loss Alert") do
      @engine.add_fact(:position, {
        symbol: "META",
        status: "open",
        entry_price: 320.00,
        current_price: 285.40,
        loss_pct: 10.8,
        shares: 100
      })
    end
    
    generate_scenario("Portfolio Risk Warning") do
      @engine.add_fact(:portfolio, {
        total_value: 250_000,
        top_holding: "AAPL",
        concentration: 32.5,
        cash_pct: 5
      })
    end
    
    generate_scenario("News-Driven Trade") do
      @engine.add_fact(:news, {
        symbol: "MSFT",
        sentiment: -0.75,
        impact: "high",
        headlines: "Major cloud outage affects services"
      })
      
      @engine.add_fact(:stock, {
        symbol: "MSFT",
        price: 395.20,
        price_change: -1.2,
        volume: 890_000
      })
    end
    
    generate_scenario("Sector Rotation Signal") do
      @engine.add_fact(:sector, {
        name: "Technology",
        performance: 7.3,
        trend: "accelerating",
        leaders: ["AAPL", "MSFT", "GOOGL"]
      })
    end
    
    generate_scenario("Complex Multi-Signal Day") do
      @engine.add_fact(:stock, {
        symbol: "AMZN",
        price: 142.50,
        volume: 1_800_000,
        price_change: 3.8,
        rsi: 72
      })
      
      @engine.add_fact(:ma_signal, {
        symbol: "AMZN",
        type: "golden_cross"
      })
      
      @engine.add_fact(:news, {
        symbol: "AMZN",
        sentiment: 0.8,
        impact: "high",
        headlines: "AWS wins major government contract"
      })
      
      @engine.add_fact(:earnings, {
        symbol: "AMZN",
        days_until: 1,
        expected_move: 6.2
      })
      
      @engine.add_fact(:options, {
        symbol: "AMZN",
        iv: 52.1,
        iv_rank: 85
      })
      
      @engine.add_fact(:market, { trend: "bullish" })
    end
  end
end

if __FILE__ == $0
  demo = TradingDemo.new
  demo.demo_scenarios
  
  puts "\n" + "="*60
  puts "TRADING SYSTEM DEMONSTRATION COMPLETE"
  puts "="*60
end