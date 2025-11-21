#!/usr/bin/env ruby
# frozen_string_literal: true

require 'debug_me'
include DebugMe


# Stock Market Technical Analysis with Bayesian Inference
#
# This example uses Bayesian inference to predict stock price movements
# based on technical indicators using real data from the sqa gem.

require_relative '../lib/bayesian_inference'
require 'sqa'
require 'sqa/tai'

$DEBUG_ME = false

# ============================================================================
# Configuration - Change these to experiment with different settings
# ============================================================================

TICKER          = 'AAPL'
DATA_ITEMS      = %w[close_price volume]
INDICATORS      = {
  sma: { period: 20 },
  rsi: { period: 14 },
  ema: { period: 12 }
}
DECIMAL_PLACES  = 1
PREDICTIONS     = %w[big_down small_down sideways small_up big_up]
BANDS           = [
  (-100.0..-5.0), # big_down
  (-5.0..-0.5), # small_down
  (-0.5..0.5), # sideways
  (0.5..5.0), # small_up
  (5.0..100.0) # big_up
]

# Bayesian inference settings
BANDWIDTH        = 0.5
UPDATE_PRIOR     = true
TRAIN_TEST_SPLIT = 0.8

# ============================================================================
# Helper Functions
# ============================================================================

def box(a_string, c = '=')
  s = a_string.size + 6
  puts
  b = c * s
  puts b
  puts c * 2 + " #{a_string} " + c * 2
  puts b
  puts
end


def pct_change(current, previous)
  return nil if current.nil? || previous.nil?
  return 0.0 if previous.zero?

  ((current - previous) / previous.abs) * 100.0
end


# Convert value to outcome index based on BANDS
def categorize(value)
  BANDS.each_with_index do |band, idx|
    return idx if band.cover?(value)
  end
  BANDS.size - 1 # Default to last category
end


# Get prediction label for outcome index
def prediction_label(outcome_idx)
  PREDICTIONS[outcome_idx] || 'unknown'
end

# Generate outcomes array from number of bands
OUTCOMES = (0...BANDS.size).to_a

# ============================================================================
# Display Configuration
# ============================================================================

box 'Bayesian Stock Market Prediction: Technical Analysis'

puts <<~HEREDOC

  Symbol: #{TICKER}
  Strategy: Predict next-day price movement using technical indicators

  Configuration:
  ==============
  Data Items:   #{DATA_ITEMS.join(', ')}
  Indicators:   #{INDICATORS.keys.map { |k| "#{k.upcase}(#{INDICATORS[k][:period]})" }.join(', ')}
  Bandwidth:    #{BANDWIDTH}
  Update Prior: #{UPDATE_PRIOR}

  Features (all as deltas from previous day):
HEREDOC

# Build feature description dynamically
feature_descriptions = []
DATA_ITEMS.each { |item| feature_descriptions << "    - #{item.gsub('_', ' ').capitalize} change (%)" }
INDICATORS.each do |name, config|
  feature_descriptions << "    - #{name.upcase}(#{config[:period]}) change"
end
puts feature_descriptions.join("\n")

puts "\n  Target: Next day's closing price change, categorized as:"
PREDICTIONS.each_with_index do |label, idx|
  band = BANDS[idx]
  band_str = if band.begin.nil?
               "< #{band.end}%"
             elsif band.end.nil?
               "> #{band.begin}%"
             else
               "#{band.begin}% to #{band.end}%"
             end
  puts "    #{idx}: #{label.gsub('_', ' ').capitalize} (#{band_str})"
end
puts

# ============================================================================
# Data Loading
# ============================================================================

puts "Loading #{TICKER} historical data..."

stock = SQA::Stock.new(ticker: TICKER)
df = stock.df.data # Get Polars DataFrame

puts "Loaded #{df.height} days of #{TICKER} data"

# Extract configured data items
data_arrays = {}
DATA_ITEMS.each do |item|
  data_arrays[item.to_sym] = df[item].to_a
end

timestamps   = df['timestamp'].to_a
first_date   = timestamps.first
last_date    = timestamps.last

puts "Date range: #{first_date} to #{last_date}"
puts

# ============================================================================
# Technical Indicator Calculation
# ============================================================================

puts 'Calculating technical indicators...'

indicator_values = {}
indicator_periods  = []

INDICATORS.each do |name, config|
  period = config[:period]
  indicator_periods << period

  begin
    # Generic indicator calculation using send
    indicator_values[name] = SQA::TAI.send(name, data_arrays[:close_price], period: period)
  rescue NoMethodError => e
    puts "Warning: Indicator #{name} not supported by SQA::TAI, skipping... (#{e.message})"
  rescue ArgumentError => e
    puts "Warning: Invalid arguments for indicator #{name}, skipping... (#{e.message})"
  end
end

indicator_summary = INDICATORS.map { |name, cfg| "#{name.upcase}(#{cfg[:period]})" }.join(', ')
puts "Calculated: #{indicator_summary}"
puts

# ============================================================================
# Feature Engineering: Calculate Deltas
# ============================================================================

puts 'Engineering features...'

features_data = []

# Start from index where all indicators are available
start_idx    = indicator_periods.max + 1
close_prices = data_arrays[:close_price]

(start_idx...(close_prices.size - 1)).each do |i|
  # Skip if any indicator values are nil
  skip = false
  indicator_values.each do |_name, values|
    if values[i].nil? || values[i - 1].nil?
      skip = true
      break
    end
  end
  next if skip

  # Build features dynamically
  features = []

  # Add data item deltas
  DATA_ITEMS.each do |item|
    values = data_arrays[item.to_sym]
    if item == 'volume'
      # Volume uses log scale
      volume_change = Math.log([values[i] / values[i - 1].to_f, 0.01].max)
      features << volume_change
    else
      # Other items use percentage change
      delta = pct_change(values[i], values[i - 1])
      next if delta.nil?

      features << delta
    end
  end

  # Add indicator deltas
  INDICATORS.keys.each do |name|
    values = indicator_values[name]
    if name == :rsi
      # RSI uses absolute difference (it's already 0-100 scale)
      features << (values[i] - values[i - 1])
    else
      # Other indicators use percentage change
      delta = pct_change(values[i], values[i - 1])
      next if delta.nil?

      features << delta
    end
  end

  # Skip if we didn't get all features
  next if features.size != (DATA_ITEMS.size + INDICATORS.size)

  # Target: next day's price movement
  next_close_delta = pct_change(close_prices[i + 1], close_prices[i])
  next if next_close_delta.nil?

  # Categorize using BANDS
  target = categorize(next_close_delta)

  features_data << {
    date: timestamps[i],
    features: features,
    target: target,
    next_close_delta: next_close_delta
  }
end

puts "Generated #{features_data.size} feature vectors"
puts

# ============================================================================
# Data Splitting
# ============================================================================

split_idx  = (features_data.size * TRAIN_TEST_SPLIT).to_i
train_data = features_data[0...split_idx]
test_data  = features_data[split_idx..]

puts "Training set: #{train_data.size} samples"
puts "Test set: #{test_data.size} samples"
puts

# Show distribution
train_dist = train_data.group_by { |d| d[:target] }.transform_values(&:size).sort

puts 'Training set target distribution:'
train_dist.each do |outcome, count|
  label = prediction_label(outcome)
  pct = (count.to_f / train_data.size * 100).round(DECIMAL_PLACES)
  puts "  #{outcome.to_s.rjust(2)}: #{count.to_s.rjust(4)} samples (#{pct.to_s.rjust(5)}%) - #{label}"
end
puts

# ============================================================================
# Model Training
# ============================================================================

box 'TRAINING BAYESIAN PREDICTOR'

predictor = BayesianInference.predictor(
  outcomes: OUTCOMES,
  bandwidth: BANDWIDTH,
  update_prior: UPDATE_PRIOR
)

train_data.each { |d| predictor.train(d[:features], outcome: d[:target]) }

puts predictor.summary
puts

# ============================================================================
# Model Evaluation
# ============================================================================

box 'EVALUATING ON TEST SET'

correct = 0
predictions = []

test_data.each do |data|
  posterior = predictor.predict(data[:features])
  predicted = posterior.max_outcome
  actual    = data[:target]

  correct += 1 if predicted == actual

  predictions << {
    date: data[:date],
    predicted: predicted,
    actual: actual,
    confidence: posterior.confidence,
    posterior: posterior.to_h,
    actual_delta: data[:next_close_delta]
  }
end

accuracy = (correct.to_f / test_data.size * 100).round(DECIMAL_PLACES)

puts <<~HEREDOC

  Test Set Results:
  =================
  Total predictions: #{test_data.size}
  Correct predictions: #{correct}
  Accuracy: #{accuracy}%

HEREDOC

# Per-category accuracy
category_stats = {}
OUTCOMES.each do |outcome|
  actual_count  = predictions.count { |p| p[:actual] == outcome }
  correct_count = predictions.count { |p| p[:actual] == outcome && p[:predicted] == outcome }

  if actual_count > 0
    cat_accuracy = (correct_count.to_f / actual_count * 100).round(DECIMAL_PLACES)
    category_stats[outcome] = { count: actual_count, correct: correct_count, accuracy: cat_accuracy }
  end
end

puts 'Accuracy by Category:'
category_stats.each do |outcome, stats|
  label = prediction_label(outcome)
  puts "  #{outcome.to_s.rjust(2)}: #{stats[:correct]}/#{stats[:count]} correct (#{stats[:accuracy]}%) - #{label}"
end
puts

# ============================================================================
# Sample Predictions
# ============================================================================

box 'SAMPLE PREDICTIONS (Last 10 days)'

predictions.last(10).each_with_index do |pred, idx|
  puts <<~HEREDOC

    Day #{idx + 1}: #{pred[:date]}
    ----------------
    Actual: #{pred[:actual]} (#{pred[:actual_delta].round(DECIMAL_PLACES)}% change) - #{prediction_label(pred[:actual])}
    Predicted: #{pred[:predicted]} - #{prediction_label(pred[:predicted])}
    Correct: #{pred[:actual] == pred[:predicted] ? 'YES' : 'NO'}
    Confidence: #{(pred[:confidence] * 100).round(DECIMAL_PLACES)}%

    Probability Distribution:
  HEREDOC

  pred[:posterior].sort.each do |outcome, prob|
    bar = '█' * (prob * 50).round
    marker = outcome == pred[:predicted] ? '← Predicted' : ''
    marker = '← ACTUAL' if outcome == pred[:actual]
    label = prediction_label(outcome)
    puts "      #{outcome.to_s.rjust(2)} (#{label.ljust(11)}): #{(prob * 100).round(DECIMAL_PLACES).to_s.rjust(5)}% #{bar} #{marker}"
  end
end

# ============================================================================
# Confusion Matrix
# ============================================================================

box 'CONFUSION MATRIX'

confusion = Hash.new { |h, k| h[k] = Hash.new(0) }
predictions.each { |pred| confusion[pred[:actual]][pred[:predicted]] += 1 }

puts "\nActual \\ Predicted:  " + OUTCOMES.map { |o| o.to_s.rjust(4) }.join('')
puts '-' * (20 + OUTCOMES.size * 4)

OUTCOMES.each do |actual|
  label = prediction_label(actual)
  row = OUTCOMES.map { |pred| confusion[actual][pred].to_s.rjust(4) }.join('')
  puts "#{actual.to_s.rjust(2)} (#{label.ljust(11)}): #{row}"
end

puts <<~HEREDOC

  Key Insights:
  =============
  1. Bayesian inference provides full probability distributions
  2. Confidence scores help identify high-certainty predictions
  3. Delta-based features improve generalization
  4. Technical indicators capture momentum and trend patterns
  5. The #{PREDICTIONS.size}-category system provides nuanced predictions

  Experiment Ideas:
  =================
  - Adjust BANDS to create tighter or wider prediction ranges
  - Change BANDWIDTH (0.3 - 1.0) to control sensitivity
  - Add more INDICATORS: :ema, :macd, :bbands
  - Try different indicator periods
  - Test on different stocks (change TICKER)
  - Add more DATA_ITEMS like high_price, low_price

HEREDOC

debug_me 'Completed'
