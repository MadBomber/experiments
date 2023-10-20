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


require 'sqa'; required_sqa_version = SemVersion("0.0.18")
require 'sqa/cli'
require 'ostruct'
require 'tty-table'


if SQA.version >= required_sqa_version
  SQA.init("--data-dir #{Nenv.home}/Documents/sqa_data/")
else
  STDERR.puts <<~EOS

    ERROR: SQA version too old: #{SQA.version}
           This program needs:  #{required_sqa_version}

  EOS
  exit(1)
end


###############################################
## Class patches.  SMELL !!!
#

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


# Example trading strategy
class MyClass
  def self.my_method(vector)
    vector.rsi[:rsi]
  end
end



#
##
###############################################
## Methods for SQA inclusion???
#

def set_av_api_key
  Alphavantage.configure do |config|
    config.api_key = SQA.av.key
  end
end


def puts_table(title: "An SQA::DataFrame", df:)
  the_table = TTY::Table.new(
                df.keys,
                df.rows
              )

  alignments = []

  df.row(0).each do |v|
    alignments << (v.is_a?(String) ? :left : :right)
  end

  puts title
  puts  the_table.render(
          :unicode,
          {
            padding:    [0, 0, 0, 0],
            alignments: alignments,
          }
        )
end

# natrix is an Array or Arrays where the
# first column is a String lable.  The remaining
# columns are Float values
#
# The first row is the actual values.
# The remain rows are the results from different
# predictors
#
# Returns an Array of winners - which predictor came closest
# to the actual value.  And an Array of those deltas.
#
def closest_prediction(matrix)
  actuals     = matrix[0][1..]
  predictions = matrix[1..]
  closest     = []
  deltas      = ["Delta"]
  winners     = ["Winner"]

  actuals.each_with_index do |actual, x|
    closest   = predictions.min_by{|prediction| (prediction[x+1].to_f - actual.to_f).abs }
    delta     = (closest[x+1].to_f - actual.to_f).abs
    winners   << closest[0]
    deltas    << delta.round(2)
  end

  [winners, deltas]
end


# matrix is an Array of Arrays where the
# first column is a label.  The remaining columns are Floats
#
# The first row is actual values.  The remaining rows are
# predicted values.
#
# returns the min and max values for each colum of the predictions.
#
def min_max_columns(given_matrix)
  matrix = given_matrix.dup # NOTE: was thinking about side-effects
  matrix = matrix[1..].map { |row| row[1..] }

  max_values = ["Highs"]
  min_values = ["Lows"]

  # Loop through each column (after having transposed the matrix)
  matrix.transpose.each do |col|
    max_values << col.map(&:to_f).max
    min_values << col.map(&:to_f).min
  end

  [min_values, max_values]
end

#
##
###############################################
## Main Application Methods
#

def tickers
  @tickers ||= TEST_WITH || PORTFOLIO_DF.ticker.sort

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


# record a recommend trade
#
def trade(ticker, signal, shares, price)
  # TODO: insert row into TRADES_DF

  debug_me("== TRADE =="){[
    :ticker,
    :signal,
    :shares,
    :price
  ]}
end


def magic(vector)
  0 == rand(2) ? :spend : :save
end



#
##
###############################################

trades_transformers = {
  shares: -> (v) { v.to_i},
  price:  -> (v) { (v.to_f + 0.004).round(3)}
}


portfolio_transformers = {
  pe:  -> (v) { (v.to_f + 0.004).round(3)}
}


PORTFOLIO = Pathname.new SQA.config.data_dir + "portfolio.csv"
TRADES    = Pathname.new SQA.config.data_dir + "trades.csv"

unless PORTFOLIO.exist?
  puts
  puts "ERROR: The #{PORTFOLIO.basename} file does not exist at #{PORTFOLIO}"
  puts
  exit(-1)
end


PORTFOLIO_DF  = SQA::DataFrame.load source: PORTFOLIO,  transformers: portfolio_transformers
TRADES_DF     = SQA::DataFrame.load source: TRADES,     transformers: trades_transformers

print "\nportfolio cols: "
puts PORTFOLIO_DF.vectors.join(', ')

print "\ntickers: "
puts PORTFOLIO_DF.ticker.join(', ')


puts
puts_table(title: "Trades", df: TRADES_DF)
puts


puts
puts_table(title: "Portfolio", df: PORTFOLIO_DF)
puts


# Buy/Sell signals from trading strategies
signals = []

#################################
# Setup Some Trading Strategies #
#################################

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

ss.add method(:magic)

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
  ap e.backtrace
  raise
end


period = 15 # size of last window to consider


stocks.each do |stock|
  ticker    = stock.ticker
  data      = stock.df      # FIXME: chanage data to df

  # The last timestamp and adjusted closing price
  # on file for this stock

  timestamp = data.timestamp.last
  adj_close = data.adj_close_price.last

  puts
  puts "="*62
  puts "== #{ticker}"
  puts "== #{timestamp} at #{adj_close}"
  puts
  ap stock.overview
  puts

  puts "Adjust Close Prices"
  puts "Last Period Descriptive Statistics"
  puts "=================================="
  puts

  stats = data.adj_close_price.last(15).sample_summary

  # stats.each_pair do |k,v|
  #   if :number == k
  #     stats[k] = v.to_i
  #   else
  #     stats[k] = v.round(3)
  #   end
  # end

  ap stats


  ##############################
  ## Calculate the Indicators ##
  ##############################


  v         = OpenStruct.new   # v, as in vector of values

  # Convert historical data to Arrays because the
  # SQA::Indicator methods take Arry type as input.

  prices    = data.adj_close_price
  volumes   = data.volume

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


  # save indicators
  stock.indicators = v.to_h


  ############################################
  # Make predictions

  stock.indicators.pnv   = SQAI.pnv(stock,  5)
  stock.indicators.pnv2  = SQAI.pnv2(stock, 5)
  stock.indicators.pnv3  = SQAI.pnv3(stock, 5)
  stock.indicators.pnv4  = SQAI.pnv4(stock, 5)
  stock.indicators.pnv5  = SQAI.pnv5(stock, 5)


  ########################################
  ## Report Recommendations and Indicators

  v = stock.indicators

  puts
  puts "Trade Recommendations"
  print "  #{ticker}: "
  puts ss.execute(v).join(', ')


  puts
  puts "Indicators:"
  ap stock.indicators
end


###################################################
## Apply some prediction indicators to see how well
## they compare to the actuals

predictors = %i[ pnv pnv2 pnv3 pnv4 pnv5]

stocks.each do |stock|
  puts "="*64
  puts "== #{stock.ticker}"
  puts
  ap stock.overview
  puts

  #[3,5,10].each do |window|
  [10].each do |window|
    headers = %w[ Predictor ]
    (1..window).each do |x|
      headers << x
    end

    actual  = stock.df.adj_close_price.last(window)

    entry   = ["Actual"]
    actual.each do |v|
      entry  << sprintf("%.1f", v.round(1))
    end
    values = [ entry ]



    predictors.each do |which|
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

=begin
At this point values is a matrix that looks like this:
  ┌─────────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
  │        0│    1│    2│    3│    4│    5│    6│    7│    8│    9│   10│
  ├─────────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
0 │   Actual│177.5│179.0│178.4│179.8│180.7│178.9│178.7│177.2│175.8│175.5│
1 │      pnv│177.4│178.6│179.9│181.1│182.4│183.6│184.8│186.1│187.3│188.6│
2 │     pnv2│174.3│173.7│173.7│173.1│172.8│172.7│172.7│173.3│173.3│173.3│
3 │     pnv3│175.7│177.4│167.9│168.9│171.0│171.7│176.3│171.1│174.9│176.2│
4 │     pnv4│174.9│176.2│177.5│176.1│178.7│179.2│179.5│177.9│173.7│175.0│
5 │     pnv5│184.9│195.5│206.7│218.5│231.0│244.3│258.2│273.0│288.7│305.2│
  └─────────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

"Actual" == values[0][0]
   "pnv" == values[1][0]

What we want to do is to find out which of the predictors came
the closes to the actual value for each prediction.

We will save that predictor's name in the winners array

=end

    # winners is an Array of Arrays
    # first row is the predictor names
    # second row is the ABS deltas from actual
    #
    winners = closest_prediction(values)
    min_max = min_max_columns(values)
    lows    = min_max.first
    highs   = min_max.last

    values << highs
    values << lows

    values << winners.first # predictor names
    values << winners.last  # delta


    #################################################
    ## Now look at the "cone" to see if the actuals were
    ## within the predicted highs and lows

    in_hl = [""] * window
    entry = ["In Cone?"]

    actuals = values.first


    actuals[1..].map(&:to_f).each_with_index do |actual, x|
      in_hl[x] = (lows[x+1] <= actual && actual <= highs[x+1]) ? "YES" : "no"
      entry << in_hl[x]
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


__END__



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
