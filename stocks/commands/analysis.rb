# sqa/lib/sqa/commands/analysis.rb

class Commands::Analysis < Commands::Base
  VERSION = "0.0.1-analysis"

  Commands.register "analysis", self

  desc "Provide an Analysis of a Portfolio"


	def initialize
    # TODO: something
	end

  def call(params)
    config = super

    puts <<~EOS
      ##################################
      ## Running the Analysis Command ##
      ##################################
    EOS
  end
end

__END__



###################################################
## This is the old thing that got me started ...

#!/usr/bin/env ruby
# experiments/stocks/analysis.rb
#
# Some technical indicators from FinTech gem
#
# optional date CLI option in format YYYY-mm-dd
# if not present uses Date.today
#


INVEST = 1000.00

require 'pathname'

require_relative 'stock'
require_relative 'datastore'


STOCKS = Pathname.pwd + "stocks.txt"
TRADES = Pathname.pwd + "trades.csv"

TRADES_FILE = File.open(TRADES, 'a')

unless STOCKS.exist?
  puts
  puts "ERROR: The 'stocks.txt' file does not exist."
  puts
  exot(-1)
end

require 'debug_me'
include DebugMe

require 'csv'
require 'date'
require 'tty-table'

require 'fin_tech'
require 'previous_dow'

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
  return @tickers unless @tickers.blank?

  @tickers = []

  STOCKS.readlines.each do |a_line|
    ticker_symbol = a_line.chomp.strip.split()&.first&.downcase
    next if ticker_symbol.blank? || '#' == ticker_symbol
    @tickers << ticker_symbol unless @tickers.include?(ticker_symbol)
  end

  @tickers.sort!
end

given_date = ARGV.first ? Date.parse(ARGV.first) : Date.today

start_date  = Date.new(2019, 1, 1)
end_date    = previous_dow(:friday, given_date)

ASOF = end_date.to_s.tr('-','')


#######################################################################
# download a CSV file from https://query1.finance.yahoo.com
# given a stock ticker symbol as a String
# start and end dates
#
# For ticker "aapl" the downloaded file will be named "aapl.csv"
# That filename will be renamed to "aapl_YYYYmmdd.csv" where the
# date suffix is the end_date of the historical data.
#
def download_historical_prices(ticker, start_date, end_date)
  data_path       = Pathname.pwd + "#{ticker}_#{ASOF}.csv"
  return if data_path.exist?

  mew_path        = Pathname.pwd + "#{ticker}.csv"

  start_timestamp = start_date.to_time.to_i
  end_timestamp   = end_date.to_time.to_i
  ticker_upcase   = ticker.upcase
  filename        = "#{ticker.downcase}.csv"

  `curl -o #{filename} "https://query1.finance.yahoo.com/v7/finance/download/#{ticker_upcase}?period1=#{start_timestamp}&period2=#{end_timestamp}&interval=1d&events=history&includeAdjustedClose=true"`

  mew_path.rename data_path
end


#######################################################################
# Read the CSV file associated with the give ticker symbol
# and the ASOF date.
#
def read_csv(ticker)
  filename  = "#{ticker.downcase}_#{ASOF}.csv"
  data      = []

  CSV.foreach(filename, headers: true) do |row|
    data << row.to_h
  end

  data
end

##########################
# record a recommend trade

def trade(ticker, signal, shares, price)
  TRADES_FILE.puts "#{ticker},#{ASOF},#{signal},#{shares},#{price}"
end

#######################################################################
###
##  Main
#


tickers.each do |ticker|
  download_historical_prices(ticker, start_date, end_date)
end

result = {}

mwfd = 14 # moving_window_forcast_days

headers = %w[ Ticker AdjClose Trend Slope M'tum RSI Analysis MACD Target Signal $]
values  = []

tickers.each do |ticker|

  data            = read_csv ticker
  prices          = data.map{|r| r["Adj Close"].to_f}
  volumes         = data.map{|r| r["volume"].to_f}

  if data.blank?
    puts
    puts "ERROR: cannot get data for #{ticker}"
    puts
    next
  end


  result[ticker]  = {
    date:       data.last["Date"],
    adj_close:  data.last["Adj Close"].to_f
  }

  result[ticker][:market] = FinTech.classify_market_profile(
                                      volumes.last(mwfd),
                                      prices.last(mwfd),
                                      prices.last(mwfd).first,
                                      prices.last
                                    )

  fr = FinTech.fibonacci_retracement( prices.last(mwfd).first,
                                      prices.last).map{|x| x.round(3)}


  puts "\n#{result[ticker][:market]} .. #{ticker}\t#{fr}"
  print "\t"
  print FinTech.head_and_shoulders_pattern?(prices.last(mwfd))
  print "\t"
  print FinTech.double_top_bottom_pattern?(prices.last(mwfd))
  print "\t"
  mr = FinTech.mean_reversion?(prices, mwfd, 0.5)
  print mr

  if mr
    print "\t"
    print FinTech.mr_mean(prices, mwfd).round(3)
  end

  print "\t"
  print FinTech.identify_wave_condition?(prices, 2*mwfd, 1.0)
  puts

  print "\t"
  print FinTech.ema_analysis(prices, mwfd).except(:ema_values)

  puts

  row  = [ ticker ]

  # result[ticker][:moving_averages]  = FinTech.sma(data, mwfd)
  result[ticker][:trend]              = FinTech.sma_trend(data, mwfd)
  result[ticker][:momentum]           = FinTech.momentum(prices, mwfd)
  result[ticker][:rsi]                = FinTech.rsi(data, mwfd)
  result[ticker][:bollinger_bands]    = FinTech.bollinger_bands(data, mwfd, 2)
  result[ticker][:macd]               = FinTech.macd(data, mwfd, 2*mwfd, mwfd/2)

  price = result[ticker][:adj_close].round(3)

  row << price
  row << result[ticker][:trend][:trend]
  row << result[ticker][:trend][:angle].round(3)
  row << result[ticker][:momentum].round(3)
  row << result[ticker][:rsi][:rsi].round(3)
  row << result[ticker][:rsi][:meaning]
  row << result[ticker][:macd].first.round(3)
  row << result[ticker][:macd].last.round(3)

  analysis  = result[ticker][:rsi][:meaning]

  signal    = ""
  macd_diff = result[ticker][:macd].first
  target    = result[ticker][:macd].last
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

the_table = TTY::Table.new(headers, values)

puts
puts "Analysis as of Friday Close: #{end_date}"

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

TRADES_FILE.close


