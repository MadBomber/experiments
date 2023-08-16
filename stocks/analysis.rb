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

require 'sqa'

require 'tty-table'


PORTFOLIO = SQA::Config.data_dir + "portfolio.csv"
TRADES    = SQA::Config.data_dir + "trades.csv"

unless PORTFOLIO.exist?
  puts
  puts "ERROR: The #{PORTFOLIO.basename} file does not exist."
  puts
  exot(-1)
end


PORTFOLIO_DF  = Daru::DataFrame.from_csv PORTFOLIO
TRADES_DF     = Daru::DataFrame.from_csv TRADES

print "\nportfolio cols: "
puts PORTFOLIO_DF.vectors.to_a.join(', ')

print "\ntickers: "
puts PORTFOLIO_DF["TICKER"].to_a.join(', ')

print "\ntrades cols: "
puts TRADES_DF.vectors.to_a.join(', ')

class NilClass
  def blank?() = true
end

class String
  def blank?() = strip().empty?
end

class Array
  def blank?() = empty?
end


def tickers
  @tickers ||= PORTFOLIO_DF['TICKER'].to_a.sort

  @tickers
end


##########################
# record a recommend trade

def trade(ticker, signal, shares, price)
  # TODO: insert row into TRADES_DF

  debug_me{[
    :ticker,
    :signal,
    :shares,
    :price
  ]}
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

result = {}

mwfd = 14 # moving_window_forcast_days

stocks.each do |stock|
  # TODO: do something with the stock
  print "ticker: #{stock.ticker} "
  puts "df size: #{stock.df.size}"
end

puts "Done."

headers = %w[ Ticker AdjClose Trend Slope M'tum RSI Analysis MACD Target Signal $]
values  = []

stocks.each do |stock|
  ticker          = stock.ticker
  data            = stock.df
  prices          = data.adj_close_price.to_a
  volumes         = data.volume.to_a


  result[ticker]  = {
    date:       data.timestamp.last(1),
    adj_close:  data.adj_close_price.last(1)
  }

  result[ticker][:market] = SQAI.market_profile(
                                      volumes.last(mwfd),
                                      prices.last(mwfd),
                                      prices.last(mwfd).first,
                                      prices.last
                                    )

  fr = SQAI.fibonacci_retracement( prices.last(mwfd).first,
                                      prices.last).map{|x| x.round(3)}


  puts "\n#{result[ticker][:market]} .. #{ticker}\t#{fr}"
  print "\t"
  print SQAI.head_and_shoulders_pattern?(prices.last(mwfd))
  print "\t"
  print SQAI.double_top_bottom_pattern(prices.last(mwfd))
  print "\t"
  mr = SQAI.mean_reversion?(prices, mwfd, 0.5)
  print mr

  if mr
    print "\t"
    print SQAI.mr_mean(prices, mwfd).round(3)
  end

  print "\t"
  print SQAI.elliott_wave_theory(prices).map{|w| w[:pattern]}.last
  puts

  print "\t"
  print SQAI.exponential_moving_average_trend(prices, mwfd).except(:ema)

  puts

  row  = [ ticker ]

  # result[ticker][:moving_averages]  = SQAI.sma(data, mwfd)
  result[ticker][:trend]              = SQAI.sma_trend(prices, mwfd)
  result[ticker][:momentum]           = SQAI.momentum(prices, mwfd).last
  result[ticker][:rsi]                = SQAI.rsi(prices, mwfd)
  result[ticker][:bollinger_bands]    = SQAI.bollinger_bands(prices, mwfd, 2)

  macd = SQAI.macd(prices, mwfd, 2*mwfd, mwfd/2)

  result[ticker][:macd]               = macd[:macd]

  price = result[ticker][:adj_close].round(3)

  row << price
  row << result[ticker][:trend][:trend]
  row << result[ticker][:trend][:angle].round(3)
  row << result[ticker][:momentum].round(3)
  row << result[ticker][:rsi][:rsi].round(3)
  row << result[ticker][:rsi][:meaning]
  row << result[ticker][:macd].round(3)  # FIXME: single float
  row << result[ticker][:macd].round(3)

  analysis  = result[ticker][:rsi][:meaning]

  signal    = ""
  macd_diff = result[ticker][:macd] # FIXME: single float
  target    = result[ticker][:macd]
  current   = result[ticker][:adj_close]

  trend_down = "down" == result[ticker][:trend][:trend]

  if current < target
    signal = "buy" unless "Over Bought" == analysis
  elsif (current > target) && trend_down
    signal = "sell" unless "Over Sold" == analysis
  end

  if "buy" == signal
    pps     = target - price
    shares  = INVEST.to_i / price.to_i
    upside  = (shares * pps).round(2)
    trade(ticker, signal, shares, price)
  elsif "sell" == signal
    pps     = target - price
    shares  = INVEST.to_i / price.to_i
    upside  = (shares * pps).round(2)
    trade(ticker, signal, shares, price)
  else
    upside = ""
  end

  row << signal
  row << upside

  values << row
end

# debug_me{[
#   :result
# ]}


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

