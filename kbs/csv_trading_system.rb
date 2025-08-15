#!/usr/bin/env ruby

require_relative 'rete2'
require 'csv'
require 'date'

class CSVTradingSystem
  def initialize(csv_file = 'sample_stock_data.csv')
    @engine = ReteII::ReteEngine.new
    @csv_file = csv_file
    @portfolio = {
      cash: 100_000,
      positions: {},
      trades: [],
      daily_values: []
    }
    @current_prices = {}
    @price_history = Hash.new { |h, k| h[k] = [] }
    setup_trading_rules
  end
  
  def setup_trading_rules
    # Rule 1: Moving Average Crossover (Golden Cross)
    ma_crossover_rule = ReteII::Rule.new(
      "moving_average_crossover",
      conditions: [
        ReteII::Condition.new(:technical_indicator, {
          indicator: "ma_crossover",
          ma_20: ->(ma20) { ma20 && ma20 > 0 },
          ma_50: ->(ma50) { ma50 && ma50 > 0 },
          signal: "golden_cross"
        }),
        ReteII::Condition.new(:stock_price, {
          symbol: ->(s) { s && s.length > 0 }
        }),
        ReteII::Condition.new(:position, { 
          symbol: ->(s) { s && s.length > 0 },
          status: "closed" 
        }, negated: true)
      ],
      action: lambda do |facts, bindings|
        indicator = facts.find { |f| f.type == :technical_indicator }
        price = facts.find { |f| f.type == :stock_price }
        
        if indicator && price && indicator[:symbol] == price[:symbol]
          symbol = price[:symbol]
          current_price = price[:close]
          
          puts "📈 GOLDEN CROSS: #{symbol}"
          puts "   20-MA: $#{indicator[:ma_20].round(2)}"
          puts "   50-MA: $#{indicator[:ma_50].round(2)}"
          puts "   Current Price: $#{current_price}"
          puts "   Signal: Strong BUY"
          
          # Execute buy order
          if @portfolio[:cash] >= current_price * 100
            execute_trade(symbol, "BUY", 100, current_price, price[:date])
          end
        end
      end,
      priority: 15
    )
    
    # Rule 2: RSI Oversold Bounce
    rsi_oversold_rule = ReteII::Rule.new(
      "rsi_oversold",
      conditions: [
        ReteII::Condition.new(:technical_indicator, {
          indicator: "rsi",
          rsi_value: ->(rsi) { rsi && rsi < 30 }
        }),
        ReteII::Condition.new(:stock_price, {
          price_change: ->(change) { change && change > 1 } # Bouncing up
        })
      ],
      action: lambda do |facts, bindings|
        indicator = facts.find { |f| f.type == :technical_indicator }
        price = facts.find { |f| f.type == :stock_price }
        
        if indicator && price && indicator[:symbol] == price[:symbol]
          symbol = price[:symbol]
          puts "🔄 RSI OVERSOLD BOUNCE: #{symbol}"
          puts "   RSI: #{indicator[:rsi_value].round(1)}"
          puts "   Price Change: +#{price[:price_change].round(2)}%"
          puts "   Signal: BUY (oversold reversal)"
          
          if @portfolio[:cash] >= price[:close] * 50
            execute_trade(symbol, "BUY", 50, price[:close], price[:date])
          end
        end
      end,
      priority: 12
    )
    
    # Rule 3: Take Profit
    take_profit_rule = ReteII::Rule.new(
      "take_profit",
      conditions: [
        ReteII::Condition.new(:position, {
          status: "open",
          profit_percent: ->(profit) { profit && profit > 10 }
        })
      ],
      action: lambda do |facts, bindings|
        position = facts.find { |f| f.type == :position }
        symbol = position[:symbol]
        current_price = @current_prices[symbol]
        
        if current_price
          puts "💰 TAKE PROFIT: #{symbol}"
          puts "   Entry: $#{position[:entry_price]}"
          puts "   Current: $#{current_price}"
          puts "   Profit: #{position[:profit_percent].round(1)}%"
          puts "   Signal: SELL (take profit)"
          
          execute_trade(symbol, "SELL", position[:shares], current_price, position[:current_date])
        end
      end,
      priority: 18
    )
    
    # Rule 4: Stop Loss
    stop_loss_rule = ReteII::Rule.new(
      "stop_loss",
      conditions: [
        ReteII::Condition.new(:position, {
          status: "open",
          loss_percent: ->(loss) { loss && loss > 8 }
        })
      ],
      action: lambda do |facts, bindings|
        position = facts.find { |f| f.type == :position }
        symbol = position[:symbol]
        current_price = @current_prices[symbol]
        
        if current_price
          puts "🛑 STOP LOSS: #{symbol}"
          puts "   Entry: $#{position[:entry_price]}"
          puts "   Current: $#{current_price}"
          puts "   Loss: #{position[:loss_percent].round(1)}%"
          puts "   Signal: SELL (stop loss)"
          
          execute_trade(symbol, "SELL", position[:shares], current_price, position[:current_date])
        end
      end,
      priority: 20
    )
    
    # Rule 5: Breakout Pattern
    breakout_rule = ReteII::Rule.new(
      "price_breakout",
      conditions: [
        ReteII::Condition.new(:technical_indicator, {
          indicator: "breakout",
          resistance_break: true,
          volume_confirmation: true
        })
      ],
      action: lambda do |facts, bindings|
        indicator = facts.find { |f| f.type == :technical_indicator }
        symbol = indicator[:symbol]
        
        puts "🚀 BREAKOUT: #{symbol}"
        puts "   Resistance Level: $#{indicator[:resistance_level]}"
        puts "   Current Price: $#{indicator[:current_price]}"
        puts "   Volume Spike: #{indicator[:volume_ratio]}x"
        puts "   Signal: BUY (momentum breakout)"
        
        if @portfolio[:cash] >= indicator[:current_price] * 75
          execute_trade(symbol, "BUY", 75, indicator[:current_price], indicator[:date])
        end
      end,
      priority: 13
    )
    
    # Rule 6: Trend Following
    trend_following_rule = ReteII::Rule.new(
      "trend_following",
      conditions: [
        ReteII::Condition.new(:technical_indicator, {
          indicator: "trend",
          trend_direction: "up",
          trend_strength: ->(strength) { strength && strength > 0.7 }
        }),
        ReteII::Condition.new(:stock_price, {
          volume: ->(vol) { vol && vol > 50_000_000 } # High volume confirmation
        })
      ],
      action: lambda do |facts, bindings|
        indicator = facts.find { |f| f.type == :technical_indicator }
        price = facts.find { |f| f.type == :stock_price }
        
        if indicator && price && indicator[:symbol] == price[:symbol]
          symbol = price[:symbol]
          puts "📊 TREND FOLLOWING: #{symbol}"
          puts "   Trend Strength: #{(indicator[:trend_strength] * 100).round(1)}%"
          puts "   Volume: #{(price[:volume] / 1_000_000.0).round(1)}M"
          puts "   Signal: BUY (strong uptrend)"
          
          if @portfolio[:cash] >= price[:close] * 60
            execute_trade(symbol, "BUY", 60, price[:close], price[:date])
          end
        end
      end,
      priority: 10
    )
    
    @engine.add_rule(ma_crossover_rule)
    @engine.add_rule(rsi_oversold_rule)
    @engine.add_rule(take_profit_rule)
    @engine.add_rule(stop_loss_rule)
    @engine.add_rule(breakout_rule)
    @engine.add_rule(trend_following_rule)
  end
  
  def calculate_moving_average(prices, period)
    return nil if prices.length < period
    prices.last(period).sum / period.to_f
  end
  
  def calculate_rsi(prices, period = 14)
    return 50 if prices.length < period + 1
    
    gains = []
    losses = []
    
    (1...prices.length).each do |i|
      change = prices[i] - prices[i-1]
      if change > 0
        gains << change
        losses << 0
      else
        gains << 0
        losses << change.abs
      end
    end
    
    return 50 if gains.length < period
    
    avg_gain = gains.last(period).sum / period.to_f
    avg_loss = losses.last(period).sum / period.to_f
    
    return 100 if avg_loss == 0
    
    rs = avg_gain / avg_loss
    100 - (100 / (1 + rs))
  end
  
  def detect_breakout(symbol, current_price, prices, volume, avg_volume)
    return false if prices.length < 20
    
    # Calculate resistance level (highest high of last 20 days)
    resistance = prices.last(20).max
    
    # Check if price breaks above resistance with volume confirmation
    price_break = current_price > resistance * 1.01 # 1% above resistance
    volume_confirmation = volume > avg_volume * 1.5  # 50% above average volume
    
    {
      resistance_break: price_break,
      volume_confirmation: volume_confirmation,
      resistance_level: resistance,
      current_price: current_price,
      volume_ratio: volume / avg_volume.to_f
    }
  end
  
  def calculate_trend_strength(prices)
    return 0.5 if prices.length < 10
    
    # Simple trend strength based on price momentum
    recent_avg = prices.last(5).sum / 5.0
    older_avg = prices[-10..-6].sum / 5.0
    
    strength = (recent_avg - older_avg) / older_avg
    [[strength, 0].max, 1].min # Clamp between 0 and 1
  end
  
  def execute_trade(symbol, action, shares, price, date)
    if action == "BUY"
      cost = shares * price
      if @portfolio[:cash] >= cost
        @portfolio[:cash] -= cost
        @portfolio[:positions][symbol] = {
          symbol: symbol,
          shares: shares,
          entry_price: price,
          entry_date: date,
          status: "open"
        }
        
        trade = {
          symbol: symbol,
          action: action,
          shares: shares,
          price: price,
          date: date,
          value: cost
        }
        @portfolio[:trades] << trade
        
        puts "   ✅ EXECUTED: #{action} #{shares} shares of #{symbol} at $#{price}"
        puts "   💰 Cash Remaining: $#{@portfolio[:cash].round(2)}"
      end
    elsif action == "SELL"
      if @portfolio[:positions][symbol] && @portfolio[:positions][symbol][:status] == "open"
        proceeds = shares * price
        @portfolio[:cash] += proceeds
        
        position = @portfolio[:positions][symbol]
        profit = proceeds - (position[:shares] * position[:entry_price])
        
        @portfolio[:positions][symbol][:status] = "closed"
        @portfolio[:positions][symbol][:exit_price] = price
        @portfolio[:positions][symbol][:exit_date] = date
        @portfolio[:positions][symbol][:profit] = profit
        
        trade = {
          symbol: symbol,
          action: action,
          shares: shares,
          price: price,
          date: date,
          value: proceeds,
          profit: profit
        }
        @portfolio[:trades] << trade
        
        puts "   ✅ EXECUTED: #{action} #{shares} shares of #{symbol} at $#{price}"
        puts "   💰 Profit/Loss: $#{profit.round(2)}"
        puts "   💰 Cash: $#{@portfolio[:cash].round(2)}"
      end
    end
  end
  
  def update_positions(date)
    @portfolio[:positions].each do |symbol, position|
      if position[:status] == "open" && @current_prices[symbol]
        current_price = @current_prices[symbol]
        entry_price = position[:entry_price]
        shares = position[:shares]
        
        current_value = shares * current_price
        entry_value = shares * entry_price
        
        profit_loss = current_value - entry_value
        profit_percent = (profit_loss / entry_value) * 100
        loss_percent = profit_percent < 0 ? profit_percent.abs : 0
        
        position[:current_price] = current_price
        position[:current_value] = current_value
        position[:unrealized_pnl] = profit_loss
        position[:profit_percent] = profit_percent > 0 ? profit_percent : 0
        position[:loss_percent] = loss_percent
        position[:current_date] = date
        
        # Add updated position as fact for rules to evaluate
        @engine.add_fact(:position, position)
      end
    end
  end
  
  def process_csv_data
    puts "🏦 CSV TRADING SYSTEM - Historical Backtesting"
    puts "=" * 70
    puts "Initial Capital: $#{@portfolio[:cash].to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
    puts "=" * 70
    
    CSV.foreach(@csv_file, headers: true) do |row|
      date = Date.parse(row['Date'])
      symbol = row['Symbol']
      open_price = row['Open'].to_f
      high = row['High'].to_f
      low = row['Low'].to_f
      close = row['Close'].to_f
      volume = row['Volume'].to_i
      
      # Store price history
      @price_history[symbol] << close
      @current_prices[symbol] = close
      
      # Calculate price change from previous day
      price_change = 0
      if @price_history[symbol].length > 1
        prev_close = @price_history[symbol][-2]
        price_change = ((close - prev_close) / prev_close) * 100
      end
      
      puts "\n📅 #{date} - Processing #{symbol}"
      puts "   OHLC: $#{open_price} / $#{high} / $#{low} / $#{close}"
      puts "   Volume: #{(volume / 1_000_000.0).round(1)}M"
      puts "   Change: #{price_change >= 0 ? '+' : ''}#{price_change.round(2)}%"
      
      # Clear previous facts
      @engine.working_memory.facts.clear
      
      # Add current price fact
      @engine.add_fact(:stock_price, {
        symbol: symbol,
        date: date,
        open: open_price,
        high: high,
        low: low,
        close: close,
        volume: volume,
        price_change: price_change
      })
      
      # Calculate and add technical indicators
      if @price_history[symbol].length >= 50
        ma_20 = calculate_moving_average(@price_history[symbol], 20)
        ma_50 = calculate_moving_average(@price_history[symbol], 50)
        
        # Golden Cross detection
        if ma_20 && ma_50 && ma_20 > ma_50
          prev_ma_20 = calculate_moving_average(@price_history[symbol][0..-2], 20)
          prev_ma_50 = calculate_moving_average(@price_history[symbol][0..-2], 50)
          
          if prev_ma_20 && prev_ma_50 && prev_ma_20 <= prev_ma_50
            @engine.add_fact(:technical_indicator, {
              symbol: symbol,
              indicator: "ma_crossover",
              ma_20: ma_20,
              ma_50: ma_50,
              signal: "golden_cross",
              date: date
            })
          end
        end
      end
      
      # RSI calculation
      if @price_history[symbol].length >= 15
        rsi = calculate_rsi(@price_history[symbol])
        @engine.add_fact(:technical_indicator, {
          symbol: symbol,
          indicator: "rsi",
          rsi_value: rsi,
          date: date
        })
      end
      
      # Breakout detection
      if @price_history[symbol].length >= 20
        avg_volume = @price_history[symbol].length >= 20 ? 
          @price_history[symbol].last(20).sum / 20.0 * 45_000_000 : 45_000_000
        
        breakout_data = detect_breakout(symbol, close, @price_history[symbol], volume, avg_volume)
        
        if breakout_data[:resistance_break] && breakout_data[:volume_confirmation]
          @engine.add_fact(:technical_indicator, {
            symbol: symbol,
            indicator: "breakout",
            resistance_break: true,
            volume_confirmation: true,
            resistance_level: breakout_data[:resistance_level],
            current_price: close,
            volume_ratio: breakout_data[:volume_ratio],
            date: date
          })
        end
      end
      
      # Trend analysis
      if @price_history[symbol].length >= 10
        trend_strength = calculate_trend_strength(@price_history[symbol])
        
        @engine.add_fact(:technical_indicator, {
          symbol: symbol,
          indicator: "trend",
          trend_direction: trend_strength > 0.6 ? "up" : "down",
          trend_strength: trend_strength,
          date: date
        })
      end
      
      # Update existing positions
      update_positions(date)
      
      # Run the inference engine
      @engine.run
      
      # Calculate portfolio value
      portfolio_value = @portfolio[:cash]
      @portfolio[:positions].each do |sym, pos|
        if pos[:status] == "open"
          portfolio_value += pos[:shares] * @current_prices[sym]
        end
      end
      
      @portfolio[:daily_values] << {
        date: date,
        portfolio_value: portfolio_value,
        cash: @portfolio[:cash],
        positions_value: portfolio_value - @portfolio[:cash]
      }
      
      puts "   📊 Portfolio Value: $#{portfolio_value.round(2)}"
    end
    
    print_final_results
  end
  
  def print_final_results
    puts "\n" + "=" * 70
    puts "FINAL TRADING RESULTS"
    puts "=" * 70
    
    # Calculate final portfolio value
    final_value = @portfolio[:cash]
    @portfolio[:positions].each do |symbol, position|
      if position[:status] == "open"
        final_value += position[:shares] * @current_prices[symbol]
      end
    end
    
    initial_value = 100_000
    total_return = final_value - initial_value
    return_pct = (total_return / initial_value) * 100
    
    puts "Initial Capital: $#{initial_value.to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
    puts "Final Value: $#{final_value.round(2).to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
    puts "Total Return: $#{total_return.round(2)} (#{return_pct.round(2)}%)"
    puts "Cash: $#{@portfolio[:cash].round(2)}"
    
    puts "\nOpen Positions:"
    @portfolio[:positions].each do |symbol, position|
      if position[:status] == "open"
        current_value = position[:shares] * @current_prices[symbol]
        puts "  #{symbol}: #{position[:shares]} shares @ $#{@current_prices[symbol]} = $#{current_value.round(2)}"
      end
    end
    
    puts "\nTrade Summary:"
    puts "Total Trades: #{@portfolio[:trades].length}"
    
    buy_trades = @portfolio[:trades].select { |t| t[:action] == "BUY" }
    sell_trades = @portfolio[:trades].select { |t| t[:action] == "SELL" }
    
    puts "Buy Orders: #{buy_trades.length}"
    puts "Sell Orders: #{sell_trades.length}"
    
    if sell_trades.any?
      profitable_trades = sell_trades.select { |t| t[:profit] > 0 }
      win_rate = (profitable_trades.length.to_f / sell_trades.length) * 100
      puts "Win Rate: #{win_rate.round(1)}%"
      
      total_profit = sell_trades.sum { |t| t[:profit] }
      puts "Realized P&L: $#{total_profit.round(2)}"
    end
    
    puts "\n" + "=" * 70
  end
end

if __FILE__ == $0
  system = CSVTradingSystem.new('sample_stock_data.csv')
  system.process_csv_data
end