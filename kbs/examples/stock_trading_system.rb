#!/usr/bin/env ruby

require_relative '../rete2'
require_relative 'rete2_dsl'
require_relative 'blackboard'
require 'date'

module StockTradingSystem
  class TradingEngine
    include ReteII::DSL::ConditionHelpers
    
    attr_reader :kb, :portfolio, :market_data, :trades_executed
    
    def initialize(initial_capital: 100000)
      @kb = setup_knowledge_base
      @portfolio = {
        cash: initial_capital,
        positions: {},
        total_value: initial_capital,
        initial_capital: initial_capital
      }
      @market_data = {}
      @trades_executed = []
      @current_time = Time.now
    end
    
    def setup_knowledge_base
      ReteII.knowledge_base do
        rule "golden_cross_signal" do
          desc "Buy signal when 50-day MA crosses above 200-day MA"
          priority 12
          
          when :technical_indicator, indicator: "moving_average"
          when :stock, volume: greater_than(1000000)
          
          not.when :position do
            symbol satisfies { |s| s }
            status "open"
          end
          
          then do |facts, bindings|
            indicator = facts.find { |f| f.type == :technical_indicator }
            stock = facts.find { |f| f.type == :stock }
            
            if indicator[:ma_50] > indicator[:ma_200] && indicator[:ma_50_prev] <= indicator[:ma_200_prev]
              puts "📈 GOLDEN CROSS: #{stock[:symbol]}"
              puts "   50-MA: #{indicator[:ma_50].round(2)}, 200-MA: #{indicator[:ma_200].round(2)}"
              puts "   Volume: #{stock[:volume].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
              puts "   ACTION: BUY SIGNAL GENERATED"
            end
          end
        end
        
        rule "death_cross_signal" do
          desc "Sell signal when 50-day MA crosses below 200-day MA"
          priority 12
          
          when :technical_indicator do
            indicator "moving_average"
            ma_50 satisfies { |v| v }
            ma_200 satisfies { |v| v }
            ma_50_prev satisfies { |v| v }
            ma_200_prev satisfies { |v| v }
          end
          
          when :position do
            status "open"
            shares greater_than(0)
          end
          
          then do |facts, bindings|
            indicator = facts.find { |f| f.type == :technical_indicator }
            position = facts.find { |f| f.type == :position }
            
            if indicator[:ma_50] < indicator[:ma_200] && indicator[:ma_50_prev] >= indicator[:ma_200_prev]
              puts "💀 DEATH CROSS: #{position[:symbol]}"
              puts "   50-MA: #{indicator[:ma_50].round(2)}, 200-MA: #{indicator[:ma_200].round(2)}"
              puts "   Position: #{position[:shares]} shares @ $#{position[:entry_price]}"
              puts "   ACTION: SELL SIGNAL GENERATED"
            end
          end
        end
        
        rule "momentum_breakout" do
          desc "Buy on strong momentum with volume confirmation"
          priority 10
          
          when :stock do
            price_change_pct greater_than(3)
            volume_ratio greater_than(1.5)
            rsi range(40, 70)
          end
          
          when :market, sentiment: one_of("bullish", "neutral")
          
          not.when :position do
            symbol satisfies { |s| s }
            status "open"
          end
          
          then do |facts, bindings|
            stock = facts.find { |f| f.type == :stock }
            puts "🚀 MOMENTUM BREAKOUT: #{stock[:symbol]}"
            puts "   Price Change: +#{stock[:price_change_pct]}%"
            puts "   Volume Ratio: #{stock[:volume_ratio]}x average"
            puts "   RSI: #{stock[:rsi]}"
            puts "   ACTION: MOMENTUM BUY"
          end
        end
        
        rule "oversold_reversal" do
          desc "Buy oversold stocks showing reversal signs"
          priority 9
          
          when :stock do
            rsi less_than(30)
            price satisfies { |p| p }
          end
          
          when :technical_indicator do
            indicator "support_level"
            level satisfies { |l| l }
          end
          
          when :market_breadth do
            advancing_issues greater_than(1500)
          end
          
          then do |facts, bindings|
            stock = facts.find { |f| f.type == :stock }
            support = facts.find { |f| f.type == :technical_indicator }
            
            if stock[:price] >= support[:level] * 0.98
              puts "🔄 OVERSOLD REVERSAL: #{stock[:symbol]}"
              puts "   RSI: #{stock[:rsi]} (oversold)"
              puts "   Price: $#{stock[:price]} near support at $#{support[:level]}"
              puts "   Market breadth positive"
              puts "   ACTION: REVERSAL BUY"
            end
          end
        end
        
        rule "trailing_stop_loss" do
          desc "Implement trailing stop loss for open positions"
          priority 15
          
          when :position do
            status "open"
            profit_pct greater_than(5)
            high_water_mark satisfies { |h| h }
          end
          
          when :stock do
            price satisfies { |p| p }
          end
          
          then do |facts, bindings|
            position = facts.find { |f| f.type == :position }
            stock = facts.find { |f| f.type == :stock }
            
            trailing_stop = position[:high_water_mark] * 0.95
            
            if stock[:price] <= trailing_stop
              puts "🛑 TRAILING STOP HIT: #{position[:symbol]}"
              puts "   Current Price: $#{stock[:price]}"
              puts "   Stop Price: $#{trailing_stop.round(2)}"
              puts "   Profit: #{position[:profit_pct]}%"
              puts "   ACTION: SELL TO LOCK PROFITS"
            end
          end
        end
        
        rule "position_sizing" do
          desc "Calculate position size based on Kelly Criterion"
          priority 8
          
          when :trading_signal do
            action "buy"
            confidence greater_than(0.6)
            expected_return satisfies { |r| r }
          end
          
          when :portfolio do
            cash greater_than(1000)
            risk_tolerance satisfies { |r| r }
          end
          
          then do |facts, bindings|
            signal = facts.find { |f| f.type == :trading_signal }
            portfolio = facts.find { |f| f.type == :portfolio }
            
            win_prob = signal[:confidence]
            win_loss_ratio = signal[:expected_return]
            kelly_pct = (win_prob * win_loss_ratio - (1 - win_prob)) / win_loss_ratio
            adjusted_kelly = kelly_pct * portfolio[:risk_tolerance]
            position_size = portfolio[:cash] * [adjusted_kelly, 0.25].min
            
            puts "📊 POSITION SIZING: #{signal[:symbol]}"
            puts "   Kelly %: #{(kelly_pct * 100).round(1)}%"
            puts "   Adjusted Size: #{(adjusted_kelly * 100).round(1)}%"
            puts "   Dollar Amount: $#{position_size.round(0)}"
          end
        end
        
        rule "sector_rotation" do
          desc "Rotate into outperforming sectors"
          priority 7
          
          when :sector_performance do
            sector satisfies { |s| s }
            relative_strength greater_than(1.1)
            trend "upward"
          end
          
          when :position do
            sector satisfies { |s| s }
            profit_pct less_than(2)
          end
          
          then do |facts, bindings|
            strong_sector = facts.find { |f| f.type == :sector_performance }
            weak_position = facts.find { |f| f.type == :position }
            
            if strong_sector[:sector] != weak_position[:sector]
              puts "🔄 SECTOR ROTATION SIGNAL"
              puts "   From: #{weak_position[:sector]} (weak)"
              puts "   To: #{strong_sector[:sector]} (RS: #{strong_sector[:relative_strength]})"
              puts "   ACTION: ROTATE PORTFOLIO"
            end
          end
        end
        
        rule "correlation_hedge" do
          desc "Hedge positions with high correlation"
          priority 6
          
          when :correlation do
            correlation greater_than(0.8)
            symbol1 satisfies { |s| s }
            symbol2 satisfies { |s| s }
          end
          
          when :position do
            symbol satisfies { |s| s }
            value greater_than(10000)
          end
          
          then do |facts, bindings|
            correlation = facts.find { |f| f.type == :correlation }
            position = facts.find { |f| f.type == :position }
            
            if [correlation[:symbol1], correlation[:symbol2]].include?(position[:symbol])
              puts "⚠️  HIGH CORRELATION WARNING"
              puts "   Symbols: #{correlation[:symbol1]} <-> #{correlation[:symbol2]}"
              puts "   Correlation: #{correlation[:correlation]}"
              puts "   ACTION: CONSIDER HEDGING OR DIVERSIFYING"
            end
          end
        end
        
        rule "earnings_play" do
          desc "Trade around earnings announcements"
          priority 11
          
          when :earnings_calendar do
            symbol satisfies { |s| s }
            days_until range(1, 5)
            expected_move greater_than(5)
          end
          
          when :options do
            symbol satisfies { |s| s }
            implied_volatility greater_than(30)
            iv_rank greater_than(50)
          end
          
          then do |facts, bindings|
            earnings = facts.find { |f| f.type == :earnings_calendar }
            options = facts.find { |f| f.type == :options }
            
            puts "💰 EARNINGS PLAY: #{earnings[:symbol]}"
            puts "   Days to Earnings: #{earnings[:days_until]}"
            puts "   Expected Move: ±#{earnings[:expected_move]}%"
            puts "   IV: #{options[:implied_volatility]}% (Rank: #{options[:iv_rank]})"
            puts "   ACTION: CONSIDER VOLATILITY STRATEGY"
          end
        end
        
        rule "risk_concentration" do
          desc "Alert on concentrated risk exposure"
          priority 14
          
          when :portfolio_metrics do
            concentration_ratio greater_than(0.3)
            top_holding satisfies { |h| h }
          end
          
          when :market, volatility: greater_than(25)
          
          then do |facts, bindings|
            metrics = facts.find { |f| f.type == :portfolio_metrics }
            
            puts "⚠️  CONCENTRATION RISK ALERT"
            puts "   Top Holding: #{metrics[:top_holding]}"
            puts "   Concentration: #{(metrics[:concentration_ratio] * 100).round(1)}%"
            puts "   Market Volatility Elevated"
            puts "   ACTION: REDUCE POSITION SIZE"
          end
        end
        
        rule "gap_fade" do
          desc "Fade large opening gaps"
          priority 8
          
          when :market_open do
            gap_percentage greater_than(2)
            direction satisfies { |d| d }
            volume satisfies { |v| v }
          end
          
          when :stock do
            symbol satisfies { |s| s }
            average_true_range satisfies { |atr| atr }
          end
          
          then do |facts, bindings|
            gap = facts.find { |f| f.type == :market_open }
            stock = facts.find { |f| f.type == :stock }
            
            if gap[:gap_percentage] > 2 * (stock[:average_true_range] / stock[:price] * 100)
              direction = gap[:direction] == "up" ? "SHORT" : "LONG"
              puts "📉 GAP FADE OPPORTUNITY: #{stock[:symbol]}"
              puts "   Gap: #{gap[:direction]} #{gap[:gap_percentage]}%"
              puts "   ATR Multiple: #{(gap[:gap_percentage] / (stock[:average_true_range] / stock[:price] * 100)).round(1)}x"
              puts "   ACTION: #{direction} FADE TRADE"
            end
          end
        end
        
        rule "vwap_reversion" do
          desc "Trade VWAP mean reversion"
          priority 7
          
          when :intraday do
            symbol satisfies { |s| s }
            price satisfies { |p| p }
            vwap satisfies { |v| v }
            distance_from_vwap satisfies { |d| d.abs > 2 }
          end
          
          when :volume_profile do
            symbol satisfies { |s| s }
            poc satisfies { |p| p }
          end
          
          then do |facts, bindings|
            intraday = facts.find { |f| f.type == :intraday }
            profile = facts.find { |f| f.type == :volume_profile }
            
            direction = intraday[:distance_from_vwap] > 0 ? "OVERBOUGHT" : "OVERSOLD"
            target = intraday[:vwap]
            
            puts "📊 VWAP REVERSION: #{intraday[:symbol]}"
            puts "   Status: #{direction}"
            puts "   Current: $#{intraday[:price]}"
            puts "   VWAP: $#{intraday[:vwap].round(2)}"
            puts "   POC: $#{profile[:poc].round(2)}"
            puts "   ACTION: MEAN REVERSION TRADE TO $#{target.round(2)}"
          end
        end
        
        rule "news_sentiment" do
          desc "React to news sentiment changes"
          priority 13
          
          when :news do
            symbol satisfies { |s| s }
            sentiment_score satisfies { |s| s.abs > 0.7 }
            volume greater_than(10)
            recency less_than(60)
          end
          
          when :stock do
            symbol satisfies { |s| s }
            price_change_pct range(-2, 2)
          end
          
          then do |facts, bindings|
            news = facts.find { |f| f.type == :news }
            stock = facts.find { |f| f.type == :stock }
            
            sentiment = news[:sentiment_score] > 0 ? "POSITIVE" : "NEGATIVE"
            action = news[:sentiment_score] > 0 ? "BUY" : "SELL"
            
            puts "📰 NEWS SENTIMENT: #{news[:symbol]}"
            puts "   Sentiment: #{sentiment} (#{news[:sentiment_score]})"
            puts "   News Volume: #{news[:volume]} articles"
            puts "   Price Reaction: #{stock[:price_change_pct]}%"
            puts "   ACTION: #{action} ON SENTIMENT"
          end
        end
      end
    end
    
    def simulate_market_data(symbol, base_price = 100)
      volatility = 0.02
      trend = rand(-0.001..0.001)
      
      @market_data[symbol] ||= {
        price: base_price,
        ma_50: base_price,
        ma_200: base_price,
        volume: 1000000 + rand(500000),
        rsi: 50
      }
      
      data = @market_data[symbol]
      
      price_change = data[:price] * (trend + volatility * (rand - 0.5))
      data[:price] = (data[:price] + price_change).round(2)
      data[:ma_50] = (data[:ma_50] * 0.98 + data[:price] * 0.02).round(2)
      data[:ma_200] = (data[:ma_200] * 0.995 + data[:price] * 0.005).round(2)
      data[:volume] = (data[:volume] * (0.8 + rand * 0.4)).to_i
      
      rsi_change = (data[:price] > base_price) ? 1 : -1
      data[:rsi] = [[data[:rsi] + rsi_change * rand(5), 0].max, 100].min
      
      data
    end
    
    def run_simulation(symbols: ["AAPL", "GOOGL", "MSFT", "AMZN"], iterations: 10)
      puts "\n" + "=" * 80
      puts "STOCK TRADING SYSTEM SIMULATION"
      puts "=" * 80
      puts "Initial Capital: $#{@portfolio[:initial_capital].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
      puts "Trading Symbols: #{symbols.join(', ')}"
      puts "=" * 80
      
      iterations.times do |i|
        puts "\n⏰ MARKET TICK #{i + 1} - #{(@current_time + i * 60).strftime('%H:%M:%S')}"
        puts "-" * 60
        
        @kb.reset
        
        @kb.fact :market, sentiment: ["bullish", "neutral", "bearish"].sample, volatility: rand(15..35)
        @kb.fact :market_breadth, advancing_issues: rand(1000..2500), declining_issues: rand(500..2000)
        
        symbols.each do |symbol|
          data = simulate_market_data(symbol, 100 + rand(50))
          
          @kb.fact :stock, {
            symbol: symbol,
            price: data[:price],
            volume: data[:volume],
            rsi: data[:rsi],
            price_change_pct: ((data[:price] - (data[:price] - rand(-5..5))) / data[:price] * 100).round(2),
            volume_ratio: (data[:volume] / 1000000.0).round(2),
            average_true_range: rand(1.0..3.0).round(2)
          }
          
          @kb.fact :technical_indicator, {
            symbol: symbol,
            indicator: "moving_average",
            ma_50: data[:ma_50],
            ma_200: data[:ma_200],
            ma_50_prev: data[:ma_50] - rand(-1..1),
            ma_200_prev: data[:ma_200] - rand(-0.5..0.5)
          }
          
          @kb.fact :technical_indicator, {
            symbol: symbol,
            indicator: "support_level",
            level: data[:price] * 0.95
          }
          
          if rand > 0.7
            @kb.fact :news, {
              symbol: symbol,
              sentiment_score: rand(-1.0..1.0).round(2),
              volume: rand(5..50),
              recency: rand(10..120)
            }
          end
          
          if rand > 0.8
            @kb.fact :earnings_calendar, {
              symbol: symbol,
              days_until: rand(1..30),
              expected_move: rand(3..15).round(1)
            }
            
            @kb.fact :options, {
              symbol: symbol,
              implied_volatility: rand(20..80),
              iv_rank: rand(0..100)
            }
          end
        end
        
        if rand > 0.5
          @kb.fact :correlation, {
            symbol1: symbols.sample,
            symbol2: symbols.sample,
            correlation: rand(0.5..0.95).round(2)
          }
        end
        
        if @portfolio[:positions].any?
          position = @portfolio[:positions].values.sample
          @kb.fact :position, position if position
        end
        
        @kb.fact :portfolio, {
          cash: @portfolio[:cash],
          risk_tolerance: 0.5
        }
        
        @kb.fact :portfolio_metrics, {
          concentration_ratio: @portfolio[:positions].any? ? 
            @portfolio[:positions].values.map { |p| p[:value] }.max.to_f / @portfolio[:total_value] : 0,
          top_holding: @portfolio[:positions].any? ? 
            @portfolio[:positions].max_by { |_, p| p[:value] }&.first : "None"
        }
        
        @kb.run
        
        sleep(0.5) if i < iterations - 1
      end
      
      puts "\n" + "=" * 80
      puts "SIMULATION COMPLETE"
      puts "=" * 80
      print_portfolio_summary
    end
    
    def print_portfolio_summary
      puts "\n📊 PORTFOLIO SUMMARY"
      puts "-" * 40
      puts "Cash: $#{@portfolio[:cash].round(2).to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
      
      if @portfolio[:positions].any?
        puts "\nOpen Positions:"
        @portfolio[:positions].each do |symbol, position|
          puts "  #{symbol}: #{position[:shares]} shares @ $#{position[:entry_price]}"
        end
      else
        puts "No open positions"
      end
      
      total_value = @portfolio[:cash] + @portfolio[:positions].values.sum { |p| p[:value] || 0 }
      pnl = total_value - @portfolio[:initial_capital]
      pnl_pct = (pnl / @portfolio[:initial_capital] * 100).round(2)
      
      puts "\nTotal Portfolio Value: $#{total_value.round(2).to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
      puts "P&L: $#{pnl.round(2)} (#{pnl_pct}%)"
    end
  end
end

if __FILE__ == $0
  engine = StockTradingSystem::TradingEngine.new(initial_capital: 100000)
  engine.run_simulation(
    symbols: ["AAPL", "GOOGL", "MSFT", "NVDA", "TSLA", "META"],
    iterations: 15
  )
end