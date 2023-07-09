#!/usr/bin/env ruby
# experiments/stocks/analysis.rb 
#
# Some technical indicators:

require 'debug_me'
include DebugMe

require 'csv'
require 'date'
require 'pathname'
require 'tty-table'

require 'previous_dow'

tickers = %w[ aapl lmt t vz ge hal f orcl ]



start_date  = Date.new(2019, 1, 1)
end_date    = previous_dow(:friday)

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

#######################################################################
# Moving Averages
#
# This method takes in an array of historical prices for a stock and a 
# period (the number of days to calculate the moving average over). It 
# uses the `each_cons` method to iterate over a sliding window of closing 
# prices and calculate the moving average for each window. The method 
# returns an array of the moving averages for each window.

def moving_averages(data, period)
  if data.first.is_a? Hash
    prices = data.map{|r| r['Adj Close'].to_f}
  else
    prices = data 
  end

  moving_averages = []
  prices.each_cons(period) do |window|
    moving_average = window.sum / period.to_f
    moving_averages << moving_average
  end
  return moving_averages
end


def trend(data, period)
  closes    = data.map{|r| r['Adj Close'].to_f}
  sma       = moving_averages(closes, period)
  last_sma  = sma.last
  prev_sma  = sma[-2]
  angle     = Math.atan((last_sma - prev_sma) / period) * (180 / Math::PI)
  
  if last_sma > prev_sma
    trend = 'up'
  else
    trend = 'down'
  end

  { trend: trend, angle: angle }
end


#######################################################################
# Relative Strength Index (RSI)
#
# This method takes in an array of historical prices for a stock and a 
# period (the number of days to calculate the RSI over). It uses 
# the `each_cons` method to iterate over a sliding window of closing 
# prices and calculate the gains and losses for each window. Then, it 
# calculates the average gain and average loss for the time period and 
# uses these values to calculate the RSI. The method returns the RSI 
# value for the given period.
#
#   over_bought if rsi >= 70
#   over_sold   if rsi <= 30

def rsi(data, period)
  prices  = data.map{|r| r['Adj Close'].to_f}
  gains   = []
  losses  = []

  prices.each_cons(2) do |pair|
    change = pair[1] - pair[0]
    if change > 0
      gains   << change
      losses  << 0
    else
      gains   << 0
      losses  << -change
    end
  end

  avg_gain  = gains.first(period).sum / period.to_f
  avg_loss  = losses.first(period).sum / period.to_f
  rs        = avg_gain / avg_loss
  rsi       = 100 - (100 / (1 + rs))

  meaning = ""
  if rsi >= 70.0
    meaning = "Over Bought"
  elsif rsi <= 30.0
    meaning = "Over Sold"
  end

  return {rsi: rsi, meaning: meaning}
end


#######################################################################
# Bollinger Bands
#
# This method takes in an array of historical prices for a stock, a 
# period (the number of days to calculate the moving average and standard 
# deviation over), and the number of standard deviations to use for the 
# upper and lower Bollinger Bands. It uses the `moving_averages` method to 
# calculate the moving average for the given period, and then calculates the 
# standard deviation of the closing prices for each window of the given period. 
# Finally, it calculates the upper and lower Bollinger Bands based on the moving 
# average and standard deviation, and returns an array containing the upper and 
# lower bands.
#
# The `num_std_dev` parameter in the Bollinger Bands method specifies the number
# of standard deviations to use for the upper and lower bands. The default
# value for this parameter can depend on the specific security being analyzed
# and the time period being used.
#
# A common default value for `num_std_dev` is 2, which corresponds to the
# standard deviation of the price data over the given time period. Using a
# value of 2 for `num_std_dev` will result in the upper and lower bands being
# placed at a distance of two standard deviations from the moving average.
#
# However, the optimal value for `num_std_dev` can vary depending on the
# volatility of the security being analyzed. For highly volatile securities, a
# larger value for `num_std_dev` may be more appropriate, while for less
# volatile securities, a smaller value may be more appropriate.
#
# Ultimately, the best default value for `num_std_dev` will depend on the
# specific use case and should be chosen based on the characteristics of the
# security being analyzed and the preferences of the analyst.
#
# The difference between the upper and lower bands can
# be an indicator of how volatile the stock is.

def bollinger_bands(data, period, num_std_devs=2)
  prices              = data.map{|r| r['Adj Close'].to_f}
  moving_averages     = moving_averages(data, period)
  standard_deviations = []

  prices.each_cons(period) do |window|
    standard_deviation = Math.sqrt(window.map { |price| (price - moving_averages.last) ** 2 }.sum / period)
    standard_deviations << standard_deviation
  end

  upper_band = moving_averages.last + (num_std_devs * standard_deviations.last)
  lower_band = moving_averages.last - (num_std_devs * standard_deviations.last)
  
  return [upper_band, lower_band]
end


#######################################################################
# Moving Average Convergence Divergence (MACD)
# 

# The MACD is a trend-following momentum indicator that measures the
# relationship between two moving averages over a specified time period. The
# MACD is calculated by subtracting the long-term moving average from the
# short-term moving average.
#
# The method takes in an array of historical prices for a stock, a short period
# (the number of days to calculate the short-term moving average over), a long
# period (the number of days to calculate the long-term moving average over),
# and a signal period (the number of days to calculate the signal line moving
# average over).
#
# The method first calculates the short-term moving average by calling the
# `moving_averages` method with the `prices` array and the `short_period`
# parameter. It then calculates the long-term moving average by calling the
# `moving_averages` method with the `prices` array and the `long_period`
# parameter.
#
# Next, the method calculates the MACD line by subtracting the long-term moving
# average from the short-term moving average. This is done by taking the last
# element of the `short_ma` array (which contains the short-term moving
# averages for each window) and subtracting the last element of the `long_ma`
# array (which contains the long-term moving averages for each window).
#
# Finally, the method calculates the signal line by taking the moving average of
# the MACD line over the specified `signal_period`. This is done by calling the
# `moving_averages` method with the `short_ma` array and the `signal_period`
# parameter, and taking the last element of the resulting array.
#
# The method returns an array containing the MACD line and the signal line.
#
# Note that this is just a basic implementation of the MACD indicator, and there
# are many variations and refinements that can be made depending on the
# specific requirements of your program.
#
# The Moving Average Convergence Divergence (MACD) is a technical analysis
# indicator that is used to identify changes in momentum, direction, and trend
# for a security. The MACD is calculated by subtracting the 26-period
# exponential moving average (EMA) from the 12-period EMA.
#
# The values 1.8231937142857078 and 164.44427957142855 that you provided are
# likely the MACD line and the signal line, respectively. The MACD line is the
# difference between the 12-period EMA and the 26-period EMA, while the signal
# line is a 9-period EMA of the MACD line.
#
# The MACD line crossing above the signal line is often considered a bullish
# signal, while the MACD line crossing below the signal line is often
# considered a bearish signal. The distance between the MACD line and the
# signal line can also provide insight into the strength of the trend.
#
# Without additional context, it's difficult to interpret the specific values of
# 1.8231937142857078 and 164.44427957142855 for the MACD and signal lines of a
# stock. However, in general, the MACD can be used to identify potential buy
# and sell signals for a security, as well as to provide insight into the
# strength of the trend.

def macd(data, short_period, long_period, signal_period)
  short_ma    = moving_averages(data, short_period)
  long_ma     = moving_averages(data, long_period)
  macd_line   = short_ma.last - long_ma.last
  signal_line = moving_averages(short_ma, signal_period).last
  
  return [macd_line, signal_line]
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

headers = %w[ Ticker AdjClose Trend Slope RSI Analysis MACD Target Signal]
values  = []

tickers.each do |ticker|

  data            = read_csv ticker

  result[ticker]  = {
    date:       data.last["Date"],
    adj_close:  data.last["Adj Close"].to_f
  }


  row  = [ ticker ]

  # result[ticker][:moving_averages]  = moving_averages(data, mwfd)
  result[ticker][:trend]            = trend(data, mwfd)
  result[ticker][:rsi]              = rsi(data, mwfd)
  result[ticker][:bollinger_bands]  = bollinger_bands(data, mwfd, 2)
  result[ticker][:macd]             = macd(data, mwfd, 2*mwfd, mwfd/2)


  row << result[ticker][:adj_close].round(3)
  row << result[ticker][:trend][:trend]
  row << result[ticker][:trend][:angle].round(3)
  row << result[ticker][:rsi][:rsi].round(3)
  row << result[ticker][:rsi][:meaning]
  row << result[ticker][:macd].first.round(3)
  row << result[ticker][:macd].last.round(3)
  
  signal    = ""
  macd_diff = result[ticker][:macd].first
  target    = result[ticker][:macd].last
  current   = result[ticker][:adj_close]

  trend_down = "down" == result[ticker][:trend][:trend]

  if current < target 
    signal = "Buy"
  elsif (current > target) && trend_down
    signal = "Sell"
  end

  row << signal

  values << row
end

# debug_me{[
#   :result
# ]}


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
            :right,   # rsi
            :center,  # meaning
            :right,   # macd
            :right,   # target
            :center   # signal
          ],
        }
      )
puts 
