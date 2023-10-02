#!/usr/bin/env ruby
# experiments/stocks/analysis.rb 
#
# In case you are wondering what the frack is this?
# It is a bottom up functional design used to
# investigate stuff which will later go into the
# the sqa gem's top down design.
#
# Some technical indicators from FinTech gem
#
# optional date CLI option in format YYYY-mm-dd
# if not present uses Date.today
#

# Maximum amount to invest in each trade
INVEST    = 1000.00

# contains a subset of tickers symbols from the
# portfolio just for detailed testing.
require_relative 'test_with'

require 'amazing_print'
require 'csv'

require 'ruby-progressbar'  # Ruby/ProgressBar is a flexible text progress bar library for Ruby.


require 'nenv'
require 'debug_me'
include DebugMe

require 'alphavantage'

# require 'faraday'
# require 'nokogiri'


require 'sqa'       # v0.0.16 # dropped Daru for Rover
require 'sqa/cli'
require 'ostruct'
require 'tty-table'



SQA.init("--data-dir #{Nenv.home}/Documents/sqa_data/")

def set_av_api_key
  Alphavantage.configure do |config|
    config.api_key = SQA.av.key
  end
end


PORTFOLIO = Pathname.new SQA.config.data_dir + "portfolio.csv"
TRADES    = Pathname.new SQA.config.data_dir + "trades.csv"

unless PORTFOLIO.exist?
  puts
  puts "ERROR: The #{PORTFOLIO.basename} file does not exist at #{PORTFOLIO}"
  puts
  exit(-1)
end


PORTFOLIO_DF  = SQA::DataFrame.load PORTFOLIO
TRADES_DF     = SQA::DataFrame.load TRADES

print "\nportfolio cols: "
puts PORTFOLIO_DF.vectors.to_a.join(', ')

print "\ntickers: "
puts PORTFOLIO_DF["Ticker"].to_a.join(', ')

print "\ntrades cols: "
puts TRADES_DF.vectors.to_a.join(', ')


puts "="*62
ap PORTFOLIO_DF #.inspect(1, PORTFOLIO_DF.size)
puts "="*62

class NilClass
  def blank?()  = true
end

class String
  def blank?()  = strip().empty?
end

class Array
  def blank?()  = empty?
  def r2        = self.map{|v| v&.round(2)}
  def r3        = self.map{|v| v&.round(3)}
end

class Float
  def blank?()  = false
  def r2        = self.round(2)
  def r3        = self.round(3)
end


def tickers
  @tickers ||= TEST_WITH || PORTFOLIO_DF['Ticker'].to_a.sort

  @tickers
end



# return a recommendation as an Integer suitable to use as
# as a label in an SVM classifier.
#
#   positive integer means buy
#   negative integer means sell
#   zero means no recommendation
#
#   The magnitude of the integer is its level of emphasis
#
# Parameters:
#
# current_acp (Float) Current Adjusted Closing Price
# future_acp  (Float) Some future Adjusted Closing Price
# delta_array (Array of Float) decisions points.
#   Each element is a positive Float.  The Array has unique elements
#   and is ascending order.
#
def recommendation(current_acp, future_acp, delta_array=[1.0, 5.0])
  deltas  = Array(delta_array)
  label   = 0 # No Recommendation
  diff    = future_acp - current_acp

  deltas.each_with_index do |delta, x|
    x += 1
    label = (diff.positive? ? x : -x) if diff.abs >= delta
  end

  label
end




# Creates a libsvm formatted file for a given
# stock classified by future adjusted closing price
# window days into the future.
#
# stock   (SQA::Stock)
# window  (Integer) forecast window into the future
#
# TODO: consider extracting all of this libsvm classification
#       stuff into a different file for experimentation
#       on just one stock at a time.  Remember that the
#       purpose is to build a classification model for
#       each stock.  There is not expectation that any
#       two stocks would have the same model or the same
#       delta_array values.
#
def create_libsvm_file(stock, window)
  filename  = stock.ticker + "_libsvm.txt"
  file      = File.open(filename, 'w')
  features  = format_features(stock, window)
  labels    = get_recommendations(stock.df.adj_close_price.to_a, window).map{|v| v.to_s + " "}
  (features.size).times do |x|
    file.puts labels[x] + features[x]
  end
end


def get_recommendations(prices, window, delta_array=[1.0, 5.0])
  last_inx = prices.size - window - 1
  labels   = []

  (0..last_inx).each do |x|
    labels << recommendation(prices[x], prices[x+window], delta_array)
  end

  labels
end

# stub - placeholder
# Some of the indicators return string which will
# need to be converted into numbers because, well, math/
#
def format_features(stock, window)
  how_many = stock.df.adjusted_close_price.to_a.size

  features = []
  how_many.timex do |x|
    features << "1:1 2:2 3:3 4:4 5:5"
  end

  features
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

indicators = {}

stocks.each do |stock|
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

  # receint_history(ticker)


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

  stock.indicators = v

  ############################################
  # Make predictions

  v.pnv   = SQAI.pnv(stock,  5)
  v.pnv2  = SQAI.pnv2(stock, 5)
  v.pnv3  = SQAI.pnv3(stock, 5)
  v.pnv4  = SQAI.pnv4(stock, 5)
  v.pnv5  = SQAI.pnv5(stock, 5)


  # save predictions
  stock.indicators = v

  ########################################
  ## Report Recommendations and Indicators

  puts
  puts "Trade Recommendations"
  print "  #{ticker}: "
  puts ss.execute(v).join(', ')


  puts
  puts "Indicators:"
  ap stock.indicators.to_h
end


stocks.each do |stock|
  puts "="*64
  puts "== #{stock.ticker}"

  debug_me{[
    "stock.overview"
  ]}

  [3,5,10].each do |window|
    headers = %w[ Predictor ]
    (1..window).each do |x|
      headers << x
    end

    actual  = stock.df.adj_close_price.to_a.last(window)
    entry   = ["Actual"]
    actual.each do |v|
      entry  << sprintf("%.1f", v.round(1))
    end
    values = [ entry ]


    %i[ pnv pnv2 pnv3 pnv4 pnv5].each do |which|
      result = SQAI.send(which, stock, window, true)
      entry = [which]
      result.each do |v|
        if :pnv2 == which
          entry << sprintf("%.1f", v[1].round(1))
        else
          entry << sprintf("%.1f", v.round(1))
        end
      end

      values << entry
    end

    highs = [   0.0] * window
    lows  = [9999.9] * window

    row_inx = -1
    values.each do |row|
      row_inx += 1
      next if 0 == row_inx

      row[1..-1].each_with_index do |value, index|
        lows[index]   = [lows[index].to_f,  value.to_f].min
        highs[index]  = [highs[index].to_f, value.to_f].max
      end
    end

    entry = ['High']
    highs.each do |v|
      entry << v
    end

    values << entry


    entry = ['Low']
    lows.each do |v|
      entry << v
    end

    values << entry

    the_table = TTY::Table.new(headers, values)

    puts
    puts "Actual vs. Forecast"
    puts "==================="

    puts  the_table.render(
            :unicode,
            {
              padding:    [0, 0, 0, 0],
              alignments:  [:right]*values.first.size,
            }
          )
    puts
  end
end


# Running up against the Alpha Vantage
# 5 api calls per minute rate limitation.

wait_seconds = 60

progressbar = ProgressBar.create(
    title: 'Waiting',
    total: wait_seconds,
    format: '%t: [%B] %c/%C %j%% %e',
    output: STDERR
)

# wait_seconds.times do |x|
#   sleep 1
#   progressbar.increment
# end


debug_me{[
  "SQA::Stock.top"
]}

puts "="*64
puts "== Using the AlphaVantage gem ..."

set_av_api_key
quote = Alphavantage::TimeSeries.new(symbol: 'TSLA').quote
# quote.previous_close #=> "719.6900"
# quote.volume         #=> "27879033"

debug_me{[ :quote ]}

#####################################
## News and Sentiment

puts
puts "getting news and sentiment for aapl"
puts

# https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=demo

set_av_api_key

from_datetime_s = "20230915T0000"

news = Alphavantage::Client.new(function: 'NEWS_SENTIMENT', tickers: 'VZ', time_from: from_datetime_s ).json

ap news

# Listings is Arrany of Array
# where the first entry is the CSV headers
listings = Alphavantage::Client.new(function: 'LISTING_STATUS').csv


CSV.open('listings.csv', 'w') do |csv|
  listings.each do |row|
    csv << row
  end
end
