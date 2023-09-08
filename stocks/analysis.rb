#!/usr/bin/env ruby
# experiments/stocks/analysis.rb 
#
# Some technical indicators from FinTech gem
#
# optional date CLI option in format YYYY-mm-dd
# if not present uses Date.today
#

# Maximum amount to invest in each trade
INVEST = 1000.00

require 'amazing_print'

require 'debug_me'
include DebugMe


require 'faraday'
require 'nokogiri'


require 'sqa'       # v0.0.9
require 'sqa/cli'
require 'ostruct'
require 'tty-table'



SQA.init("--data-dir #{Nenv.home}/Documents/sqa_data/")


PORTFOLIO = Pathname.new SQA.config.data_dir + "portfolio.csv"
TRADES    = Pathname.new SQA.config.data_dir + "trades.csv"

unless PORTFOLIO.exist?
  puts
  puts "ERROR: The #{PORTFOLIO.basename} file does not exist at #{PORTFOLIO}"
  puts
  exit(-1)
end


PORTFOLIO_DF  = Daru::DataFrame.from_csv PORTFOLIO
TRADES_DF     = Daru::DataFrame.from_csv TRADES

print "\nportfolio cols: "
puts PORTFOLIO_DF.vectors.to_a.join(', ')

print "\ntickers: "
puts PORTFOLIO_DF["Ticker"].to_a.join(', ')

print "\ntrades cols: "
puts TRADES_DF.vectors.to_a.join(', ')


puts "="*62
puts PORTFOLIO_DF.inspect(1, PORTFOLIO_DF.size)
puts "="*62

class NilClass
  def blank?()  = true
end

class String
  def blank?()  = strip().empty?
end

class Array
  def blank?()  = empty?
  def r2        = self.map{|v| v.round(2)}
  def r3        = self.map{|v| v.round(3)}
end

class Float
  def blank?()  = false
  def r2        = self.round(2)
  def r3        = self.round(3)
end


def tickers
  @tickers ||= PORTFOLIO_DF['Ticker'].to_a.sort

  @tickers
end


##########################
# record a recommend trade

def trade(ticker, signal, shares, price)
  # TODO: insert row into TRADES_DF

  debug_me("== TRADE =="){[
    :ticker,
    :signal,
    :shares,
    :price
  ]}
end 

signals = []


ss = SQA::Strategy.new

ss.add(SQA::Strategy::Random) do |vector|
  case rand(10)
  when (8..)
    :buy
  when (..3)
    :sell
  else
    :hold
  end
end



ss.add(SQA::Strategy::Random) do |vector|
  case rand(10)
  when (8..)
    :sell
  when (..3)
    :buy
  else
    :keep
  end
end

def magic(vector)
  0 == rand(2) ? :spend : :save
end

ss.add method(:magic)

class MyClass
  def self.my_method(vector)
    vector.rsi[:rsi]
  end
end

ss.add MyClass.method(:my_method)


########################################################
## Update stock historical pricess from receint history

CONNECTION = Faraday.new(url: 'https://finance.yahoo.com')

def receint_history(ticker_symbol)
  response  = CONNECTION.get("/quote/#{ticker_symbol.upcase}/history")
  doc       = Nokogiri::HTML(response.body)
  table     = doc.css('table').first
  rows      = table.css('tbody tr')

  markdown  = "| Date | Open | High | Low | Close | Adj Close | Volume |\n"
  markdown += "|------|------|------|-----|-------|-----------|--------|\n"

  rows.each do |row|
    cols = row.css('td').map{|c| c&.text}

    unless cols[1]&.include?('Dividend')
       markdown += "| " + cols.join(" | ") + " | \n"
       # #{cols[0]} | #{cols[1]} | #{cols[2]} | #{cols[3]} | #{cols[4]} | #{cols[5]} | #{cols[6]} |\n"
    end
  end

  puts markdown
end


#######################################################################
###
##  Main
#

stocks = []

tickers.each do |ticker|
  stocks << SQA::Stock.new(ticker: ticker)
rescue => e
  puts "\nERROR: #{e}"
  puts   "  ticker: #{ticker}"
end

period = 14 # size of last window to consider

counter = 0

stocks.each do |stock|
  exit if counter > 3

  ticker    = stock.ticker
  data      = stock.df

  # The last timestamp and adjusted closing price
  # on file for this stock

  timestamp = data.timestamp.last
  adj_close = data.adj_close_price.last

  puts
  puts "="*62
  puts "== #{ticker}"
  puts "== #{timestamp} at #{adj_close}"
  puts

  receint_history(ticker)


  v         = OpenStruct.new   # v, as in vector of values

  # Convert historical data to Arrays because the
  # SQA::Indicator methods take Arry type as input.

  prices    = data.adj_close_price.to_a.r2
  volumes   = data.volume.to_a


  # Calculate the indicators for this stock

  v.market_profile  = SQAI.market_profile(
                        volumes.last(period),
                        prices.last(period),
                        prices.last(period).first,
                        prices.last
                      )

  v.fr  = SQAI.fibonacci_retracement(
            prices.last(period).first,
            prices.last
          ).r2

  v.hasp      = SQAI.head_and_shoulders_pattern?(prices.last(period))
  v.dtbp      = SQAI.double_top_bottom_pattern(prices.last(period))
  v.mr        = SQAI.mean_reversion?(prices, period, 0.5)
  v.mr_mean   = SQAI.mr_mean(prices, period).round(3)

  v.ewt       = SQAI.elliott_wave_theory(prices.last(4*period)).map{|w| w[:pattern]}.compact.last(3)

  v.ema               = SQAI.exponential_moving_average_trend(prices, period).except(:ema)
  v.ema[:support]     = v.ema[:support].r2
  v.ema[:resistance]  = v.ema[:resistance].r2

  # v.sma     = SQAI.simple_moving_average(prices, period).r2

  v.sma_trend         = SQAI.sma_trend(prices, period).except(:sma)
  v.sma_trend[:angle] = v.sma_trend[:angle].r2

  v.momentum  = SQAI.momentum(prices, period).last.r2

  v.rsi       = SQAI.rsi(prices, period)
  v.rsi[:rsi] = v.rsi[:rsi].r2

  bb          = SQAI.bollinger_bands(prices, period, 2)
  v.bb        = [ bb[:lower_band].r2, bb[:upper_band].r2 ]

  v.macd      = SQAI.moving_average_convergence_divergence(
                  prices,
                  period,
                  2*period,
                  period/2
                )

  v.macd[:macd]    = v.macd[:macd].last.r2
  v.macd[:signal]  = v.macd[:signal].last.r2


  puts
  puts "Trade Recommendations"
  print "  #{ticker}: "
  puts ss.execute(v).join(', ')


  puts
  puts "Metrics:"
  ap v.to_h


  counter += 1
end




__END__

the_table = TTY::Table.new(headers, values)

puts
puts "Analysis"
puts "========"
puts

puts  the_table.render(
        :unicode,
        {
          padding:    [0, 0, 0, 0],
          alignments: [
            :left,    # ticker
            :right,   # adj close
            :center,  # trend
            :right,   # slope
            :right,   # momentum
            :right,   # rsi
            :center,  # meaning / analysis
            :right,   # macd
            :right,   # target
            :center,  # signal
            :right    # upside
          ],
        }
      )
puts 

