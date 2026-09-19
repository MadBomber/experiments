# frozen_string_literal: true

# Pure-Ruby technical indicators for the demos.
#
# Replaces sqa-tai/ta_lib_ffi, which hangs against homebrew ta-lib 0.8.x
# (ta_lib_ffi 0.3.0 targets the older ta-lib ABI). No native deps.
#
# All methods return arrays aligned with the input: index i of the
# result corresponds to index i of the prices, with nil during the
# warm-up region where the indicator is undefined.
module PureRubyIndicators
  module_function

  # Simple Moving Average.
  #
  # @param prices [Array<Numeric>]
  # @param period [Integer]
  # @return [Array<Float, nil>]
  def sma(prices, period: 30)
    prices.each_index.map do |i|
      next nil if i < period - 1

      window = prices[(i - period + 1)..i]
      window.sum.to_f / period
    end
  end

  # Exponential Moving Average, seeded with the SMA of the first window.
  #
  # @param prices [Array<Numeric>]
  # @param period [Integer]
  # @return [Array<Float, nil>]
  def ema(prices, period: 30)
    alpha = 2.0 / (period + 1)
    result = Array.new(prices.size)
    prev = nil

    prices.each_with_index do |price, i|
      if i == period - 1
        prev = prices[0, period].sum.to_f / period
      elsif prev
        prev = (price - prev) * alpha + prev
      end
      result[i] = prev
    end
    result
  end

  # Relative Strength Index (Wilder's smoothing).
  #
  # @param prices [Array<Numeric>]
  # @param period [Integer]
  # @return [Array<Float, nil>] values in 0..100
  def rsi(prices, period: 14)
    result = Array.new(prices.size)
    return result if prices.size <= period

    changes = prices.each_cons(2).map { |a, b| b - a }
    avg_gain = changes[0, period].sum { |c| c.positive? ? c : 0.0 } / period
    avg_loss = changes[0, period].sum { |c| c.negative? ? -c : 0.0 } / period
    result[period] = rsi_value(avg_gain, avg_loss)

    (period...changes.size).each do |j|
      change = changes[j]
      avg_gain = (avg_gain * (period - 1) + (change.positive? ? change : 0.0)) / period
      avg_loss = (avg_loss * (period - 1) + (change.negative? ? -change : 0.0)) / period
      result[j + 1] = rsi_value(avg_gain, avg_loss)
    end
    result
  end

  # RSI from smoothed average gain/loss; 100 when there are no losses.
  #
  # @return [Float]
  def rsi_value(avg_gain, avg_loss)
    return 100.0 if avg_loss.zero?

    100.0 - (100.0 / (1.0 + avg_gain / avg_loss))
  end
end
