#!/usr/bin/env ruby

require_relative '../rete2'

class AdvancedStockTradingSystem
  def initialize
    @engine = ReteII::ReteEngine.new
    @portfolio = {
      cash: 100000,
      positions: {},
      total_value: 100000
    }
    @market_data = {}
    setup_rules
  end
  
  def setup_rules
    golden_cross = ReteII::Rule.new(
      "golden_cross",
      conditions: [
        ReteII::Condition.new(:technical, {
          indicator: "ma_crossover",
          ma50: ->(v) { v > 0 },
          ma200: ->(v) { v > 0 }
        }),
        ReteII::Condition.new(:stock, {
          volume: ->(v) { v > 1000000 }
        }),
        ReteII::Condition.new(:position, { status: "open" }, negated: true)
      ],
      action: lambda do |facts, bindings|
        tech = facts.find { |f| f.type == :technical }
        stock = facts.find { |f| f.type == :stock }
        if tech && stock && tech[:ma50] > tech[:ma200] && tech[:ma50_prev] <= tech[:ma200_prev]
          puts "📈 GOLDEN CROSS: #{stock[:symbol]}"
          puts "   50-MA: $#{tech[:ma50].round(2)}, 200-MA: $#{tech[:ma200].round(2)}"
          puts "   Volume: #{stock[:volume].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
          puts "   ACTION: Strong BUY signal"
        end
      end,
      priority: 15
    )
    
    momentum_breakout = ReteII::Rule.new(
      "momentum_breakout",
      conditions: [
        ReteII::Condition.new(:stock, {
          price_change: ->(v) { v > 3 },
          volume_ratio: ->(v) { v > 1.5 },
          rsi: ->(v) { v.between?(40, 70) }
        }),
        ReteII::Condition.new(:market, { sentiment: ->(s) { ["bullish", "neutral"].include?(s) } })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        puts "🚀 MOMENTUM BREAKOUT: #{stock[:symbol]}"
        puts "   Price Change: +#{stock[:price_change]}%"
        puts "   Volume Spike: #{stock[:volume_ratio]}x average"
        puts "   RSI: #{stock[:rsi]}"
        puts "   ACTION: Momentum BUY"
      end,
      priority: 12
    )
    
    oversold_bounce = ReteII::Rule.new(
      "oversold_bounce",
      conditions: [
        ReteII::Condition.new(:stock, {
          rsi: ->(v) { v < 30 },
          price: ->(p) { p > 0 }
        }),
        ReteII::Condition.new(:support, {
          level: ->(l) { l > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        stock = facts.find { |f| f.type == :stock }
        support = facts.find { |f| f.type == :support }
        if stock && support && stock[:price] >= support[:level] * 0.98
          puts "🔄 OVERSOLD REVERSAL: #{stock[:symbol]}"
          puts "   RSI: #{stock[:rsi]} (oversold)"
          puts "   Price: $#{stock[:price]} near support $#{support[:level].round(2)}"
          puts "   ACTION: Reversal BUY opportunity"
        end
      end,
      priority: 10
    )
    
    trailing_stop = ReteII::Rule.new(
      "trailing_stop",
      conditions: [
        ReteII::Condition.new(:position, {
          status: "open",
          profit_pct: ->(p) { p > 5 }
        }),
        ReteII::Condition.new(:stock, {
          price: ->(p) { p > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        position = facts.find { |f| f.type == :position }
        stock = facts.find { |f| f.type == :stock }
        if position && stock
          trailing_stop = position[:high_water] * 0.95
          if stock[:price] <= trailing_stop
            puts "🛑 TRAILING STOP: #{position[:symbol]}"
            puts "   Entry: $#{position[:entry_price]}"
            puts "   Current: $#{stock[:price]}"
            puts "   Stop: $#{trailing_stop.round(2)}"
            puts "   Profit: #{position[:profit_pct].round(1)}%"
            puts "   ACTION: SELL to lock profits"
          end
        end
      end,
      priority: 18
    )
    
    position_sizing = ReteII::Rule.new(
      "position_sizing",
      conditions: [
        ReteII::Condition.new(:signal, {
          action: "buy",
          confidence: ->(c) { c > 0.6 }
        }),
        ReteII::Condition.new(:portfolio, {
          cash: ->(c) { c > 1000 }
        })
      ],
      action: lambda do |facts, bindings|
        signal = facts.find { |f| f.type == :signal }
        portfolio = facts.find { |f| f.type == :portfolio }
        if signal && portfolio
          kelly = (signal[:confidence] * signal[:expected_return] - (1 - signal[:confidence])) / signal[:expected_return]
          position_size = portfolio[:cash] * [kelly * 0.25, 0.1].min
          puts "📊 POSITION SIZING: #{signal[:symbol]}"
          puts "   Confidence: #{(signal[:confidence] * 100).round}%"
          puts "   Kelly %: #{(kelly * 100).round(1)}%"
          puts "   Suggested Size: $#{position_size.round(0)}"
        end
      end,
      priority: 8
    )
    
    earnings_play = ReteII::Rule.new(
      "earnings_play",
      conditions: [
        ReteII::Condition.new(:earnings, {
          days_until: ->(d) { d.between?(1, 5) },
          expected_move: ->(m) { m > 5 }
        }),
        ReteII::Condition.new(:options, {
          iv: ->(v) { v > 30 },
          iv_rank: ->(r) { r > 50 }
        })
      ],
      action: lambda do |facts, bindings|
        earnings = facts.find { |f| f.type == :earnings }
        options = facts.find { |f| f.type == :options }
        puts "💰 EARNINGS PLAY: #{earnings[:symbol]}"
        puts "   Days to Earnings: #{earnings[:days_until]}"
        puts "   Expected Move: ±#{earnings[:expected_move]}%"
        puts "   IV: #{options[:iv]}% (Rank: #{options[:iv_rank]})"
        puts "   ACTION: Consider volatility strategy"
      end,
      priority: 11
    )
    
    sector_rotation = ReteII::Rule.new(
      "sector_rotation",
      conditions: [
        ReteII::Condition.new(:sector, {
          performance: ->(p) { p > 1.1 },
          trend: "up"
        }),
        ReteII::Condition.new(:position, {
          sector: ->(s) { s != nil },
          profit_pct: ->(p) { p < 2 }
        })
      ],
      action: lambda do |facts, bindings|
        strong_sector = facts.find { |f| f.type == :sector }
        weak_position = facts.find { |f| f.type == :position }
        if strong_sector && weak_position && strong_sector[:name] != weak_position[:sector]
          puts "🔄 SECTOR ROTATION"
          puts "   From: #{weak_position[:sector]} (underperforming)"
          puts "   To: #{strong_sector[:name]} (RS: #{strong_sector[:performance]})"
          puts "   ACTION: Rotate portfolio allocation"
        end
      end,
      priority: 7
    )
    
    risk_alert = ReteII::Rule.new(
      "risk_concentration",
      conditions: [
        ReteII::Condition.new(:portfolio_metrics, {
          concentration: ->(c) { c > 0.3 }
        }),
        ReteII::Condition.new(:market, {
          volatility: ->(v) { v > 25 }
        })
      ],
      action: lambda do |facts, bindings|
        metrics = facts.find { |f| f.type == :portfolio_metrics }
        puts "⚠️  RISK CONCENTRATION ALERT"
        puts "   Top Position: #{(metrics[:concentration] * 100).round}% of portfolio"
        puts "   Market Volatility: Elevated"
        puts "   ACTION: Reduce position sizes for risk management"
      end,
      priority: 16
    )
    
    vwap_reversion = ReteII::Rule.new(
      "vwap_reversion",
      conditions: [
        ReteII::Condition.new(:intraday, {
          distance_from_vwap: ->(d) { d.abs > 2 }
        })
      ],
      action: lambda do |facts, bindings|
        intraday = facts.find { |f| f.type == :intraday }
        direction = intraday[:distance_from_vwap] > 0 ? "OVERBOUGHT" : "OVERSOLD"
        puts "📊 VWAP REVERSION: #{intraday[:symbol]}"
        puts "   Status: #{direction}"
        puts "   Distance: #{intraday[:distance_from_vwap].round(1)} std devs"
        puts "   Current: $#{intraday[:price]}"
        puts "   VWAP: $#{intraday[:vwap].round(2)}"
        puts "   ACTION: Mean reversion trade"
      end,
      priority: 9
    )
    
    news_sentiment = ReteII::Rule.new(
      "news_sentiment",
      conditions: [
        ReteII::Condition.new(:news, {
          sentiment: ->(s) { s.abs > 0.7 },
          volume: ->(v) { v > 10 }
        }),
        ReteII::Condition.new(:stock, {
          price_change: ->(p) { p.abs < 2 }
        })
      ],
      action: lambda do |facts, bindings|
        news = facts.find { |f| f.type == :news }
        stock = facts.find { |f| f.type == :stock }
        sentiment = news[:sentiment] > 0 ? "POSITIVE" : "NEGATIVE"
        action = news[:sentiment] > 0 ? "BUY" : "SELL"
        puts "📰 NEWS CATALYST: #{stock[:symbol]}"
        puts "   Sentiment: #{sentiment} (#{news[:sentiment].round(2)})"
        puts "   News Volume: #{news[:volume]} articles"
        puts "   Price Reaction: #{stock[:price_change].round(1)}% (lagging)"
        puts "   ACTION: #{action} on sentiment divergence"
      end,
      priority: 13
    )
    
    correlation_hedge = ReteII::Rule.new(
      "correlation_warning",
      conditions: [
        ReteII::Condition.new(:correlation, {
          value: ->(v) { v > 0.8 }
        })
      ],
      action: lambda do |facts, bindings|
        corr = facts.find { |f| f.type == :correlation }
        puts "⚠️  HIGH CORRELATION"
        puts "   Pairs: #{corr[:symbol1]} <-> #{corr[:symbol2]}"
        puts "   Correlation: #{corr[:value].round(2)}"
        puts "   ACTION: Diversify or hedge positions"
      end,
      priority: 6
    )
    
    gap_fade = ReteII::Rule.new(
      "gap_fade",
      conditions: [
        ReteII::Condition.new(:gap, {
          size: ->(s) { s.abs > 2 }
        }),
        ReteII::Condition.new(:stock, {
          atr: ->(a) { a > 0 }
        })
      ],
      action: lambda do |facts, bindings|
        gap = facts.find { |f| f.type == :gap }
        stock = facts.find { |f| f.type == :stock }
        if gap && stock
          gap_multiple = gap[:size].abs / (stock[:atr] / stock[:price] * 100)
          if gap_multiple > 2
            direction = gap[:size] > 0 ? "SHORT" : "LONG"
            puts "📉 GAP FADE: #{stock[:symbol]}"
            puts "   Gap: #{gap[:size].round(1)}%"
            puts "   ATR Multiple: #{gap_multiple.round(1)}x"
            puts "   ACTION: #{direction} fade trade"
          end
        end
      end,
      priority: 8
    )
    
    @engine.add_rule(golden_cross)
    @engine.add_rule(momentum_breakout)
    @engine.add_rule(oversold_bounce)
    @engine.add_rule(trailing_stop)
    @engine.add_rule(position_sizing)
    @engine.add_rule(earnings_play)
    @engine.add_rule(sector_rotation)
    @engine.add_rule(risk_alert)
    @engine.add_rule(vwap_reversion)
    @engine.add_rule(news_sentiment)
    @engine.add_rule(correlation_hedge)
    @engine.add_rule(gap_fade)
  end
  
  def simulate_market_tick(symbols)
    symbols.each do |symbol|
      @market_data[symbol] ||= {
        price: 100 + rand(50),
        ma50: 100,
        ma200: 100,
        volume: 1000000,
        rsi: 50,
        high_water: 100
      }
      
      data = @market_data[symbol]
      
      price_change = rand(-5.0..5.0)
      data[:price] = (data[:price] * (1 + price_change / 100)).round(2)
      data[:ma50] = (data[:ma50] * 0.98 + data[:price] * 0.02).round(2)
      data[:ma200] = (data[:ma200] * 0.995 + data[:price] * 0.005).round(2)
      data[:volume] = (1000000 * (0.5 + rand * 2)).to_i
      data[:rsi] = [[data[:rsi] + rand(-10..10), 0].max, 100].min
      data[:high_water] = [data[:high_water], data[:price]].max
      
      @engine.add_fact(:stock, {
        symbol: symbol,
        price: data[:price],
        volume: data[:volume],
        rsi: data[:rsi],
        price_change: price_change,
        volume_ratio: data[:volume] / 1000000.0,
        atr: rand(1.0..3.0)
      })
      
      @engine.add_fact(:technical, {
        symbol: symbol,
        indicator: "ma_crossover",
        ma50: data[:ma50],
        ma200: data[:ma200],
        ma50_prev: data[:ma50] - rand(-1.0..1.0),
        ma200_prev: data[:ma200] - rand(-0.5..0.5)
      })
      
      @engine.add_fact(:support, {
        symbol: symbol,
        level: data[:price] * 0.95
      })
      
      if rand > 0.7
        @engine.add_fact(:intraday, {
          symbol: symbol,
          price: data[:price],
          vwap: data[:price] + rand(-2.0..2.0),
          distance_from_vwap: rand(-3.0..3.0)
        })
      end
      
      if rand > 0.8
        @engine.add_fact(:news, {
          symbol: symbol,
          sentiment: rand(-1.0..1.0),
          volume: rand(5..50)
        })
      end
      
      if rand > 0.85
        @engine.add_fact(:earnings, {
          symbol: symbol,
          days_until: rand(1..10),
          expected_move: rand(3.0..15.0)
        })
        
        @engine.add_fact(:options, {
          symbol: symbol,
          iv: rand(20..80),
          iv_rank: rand(0..100)
        })
      end
      
      if rand > 0.9
        @engine.add_fact(:gap, {
          symbol: symbol,
          size: rand(-5.0..5.0)
        })
      end
    end
    
    @engine.add_fact(:market, {
      sentiment: ["bullish", "neutral", "bearish"].sample,
      volatility: rand(10..40)
    })
    
    if @portfolio[:positions].any?
      total_value = @portfolio[:cash] + @portfolio[:positions].values.sum { |p| p[:value] }
      max_position = @portfolio[:positions].values.map { |p| p[:value] }.max || 0
      @engine.add_fact(:portfolio_metrics, {
        concentration: max_position.to_f / total_value
      })
    end
    
    @engine.add_fact(:portfolio, {
      cash: @portfolio[:cash],
      risk_tolerance: 0.5
    })
    
    if rand > 0.85
      symbols_pair = symbols.sample(2)
      @engine.add_fact(:correlation, {
        symbol1: symbols_pair[0],
        symbol2: symbols_pair[1],
        value: rand(0.5..0.95)
      })
    end
    
    sectors = ["Technology", "Healthcare", "Finance", "Energy", "Consumer"]
    @engine.add_fact(:sector, {
      name: sectors.sample,
      performance: rand(0.8..1.3),
      trend: ["up", "down", "sideways"].sample
    })
  end
  
  def run_simulation(symbols: ["AAPL", "GOOGL", "MSFT", "NVDA"], iterations: 10)
    puts "\n" + "=" * 80
    puts "ADVANCED STOCK TRADING SYSTEM"
    puts "=" * 80
    puts "Initial Capital: $100,000"
    puts "Symbols: #{symbols.join(', ')}"
    puts "Rules: #{@engine.rules.size} active trading strategies"
    puts "=" * 80
    
    iterations.times do |i|
      puts "\n⏰ MARKET TICK #{i + 1} - #{Time.now.strftime('%H:%M:%S')}"
      puts "-" * 60
      
      @engine.working_memory.facts.clear
      
      simulate_market_tick(symbols)
      
      @engine.run
      
      sleep(0.3) if i < iterations - 1
    end
    
    puts "\n" + "=" * 80
    puts "SIMULATION COMPLETE"
    puts "=" * 80
  end
end

if __FILE__ == $0
  system = AdvancedStockTradingSystem.new
  system.run_simulation(
    symbols: ["AAPL", "GOOGL", "MSFT", "NVDA", "TSLA", "META", "AMZN"],
    iterations: 12
  )
end