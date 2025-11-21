#!/usr/bin/env ruby
# frozen_string_literal: true

# Time Series Prediction Example: Bayesian Inference for Discrete Outcomes
#
# This example demonstrates the core use case: predicting a probability
# distribution over 5 discrete outcomes {-2, -1, 0, 1, 2} given three
# time series variables (x, y, z) and their historical context.
#
# Scenario: Market trend prediction
# - x: price momentum
# - y: volume indicator
# - z: volatility measure
# - outcome: next period's trend direction {-2, -1, 0, 1, 2}

require_relative '../lib/bayesian_inference'
require 'debug_me'
include DebugMe

puts <<~HEREDOC
  ================================================================
  Bayesian Time Series Prediction: Market Trend Example
  ================================================================

  Goal: Predict probability distribution over trend outcomes
    -2: Strong downtrend
    -1: Weak downtrend
     0: Neutral/sideways
     1: Weak uptrend
     2: Strong uptrend

  Features:
    x: Price momentum (normalized)
    y: Volume indicator (normalized)
    z: Volatility measure (normalized)

HEREDOC

# Create predictor
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 0.8,  # Moderate bandwidth for time series
  update_prior: true  # Learn prior from observations
)

debug_me "Initial predictor"

puts "Generating synthetic training data...\n\n"

# Generate realistic training data
# Different patterns lead to different outcomes
training_data = []

# Strong downtrend patterns (outcome = -2)
30.times do
  x = rand(-2.0..-1.0)  # Strong negative momentum
  y = rand(-1.0..0.5)   # Low to moderate volume
  z = rand(0.5..2.0)    # High volatility
  training_data << {features: [x, y, z], outcome: -2}
end

# Weak downtrend patterns (outcome = -1)
40.times do
  x = rand(-1.0..-0.3)  # Weak negative momentum
  y = rand(-0.5..1.0)   # Moderate volume
  z = rand(0.0..1.0)    # Moderate volatility
  training_data << {features: [x, y, z], outcome: -1}
end

# Neutral/sideways patterns (outcome = 0)
50.times do
  x = rand(-0.3..0.3)   # Near-zero momentum
  y = rand(-1.0..1.0)   # Variable volume
  z = rand(0.0..0.8)    # Low to moderate volatility
  training_data << {features: [x, y, z], outcome: 0}
end

# Weak uptrend patterns (outcome = 1)
40.times do
  x = rand(0.3..1.0)    # Weak positive momentum
  y = rand(-0.5..1.5)   # Moderate to high volume
  z = rand(0.0..1.0)    # Moderate volatility
  training_data << {features: [x, y, z], outcome: 1}
end

# Strong uptrend patterns (outcome = 2)
30.times do
  x = rand(1.0..2.0)    # Strong positive momentum
  y = rand(0.5..2.0)    # High volume
  z = rand(0.5..1.5)    # Moderate to high volatility
  training_data << {features: [x, y, z], outcome: 2}
end

# Shuffle and train
training_data.shuffle!
predictor.train_batch(training_data)

puts "=" * 70
puts predictor.summary
puts "=" * 70

# Test predictions
test_scenarios = [
  {
    features: [-1.5, 0.2, 1.2],
    description: "Strong negative momentum, low volume, high volatility",
    expected: "Should predict strong downtrend (-2)"
  },
  {
    features: [-0.5, 0.5, 0.5],
    description: "Weak negative momentum, moderate volume, moderate volatility",
    expected: "Should predict weak downtrend (-1)"
  },
  {
    features: [0.0, 0.0, 0.3],
    description: "Zero momentum, low volume, low volatility",
    expected: "Should predict neutral (0)"
  },
  {
    features: [0.7, 1.0, 0.6],
    description: "Positive momentum, high volume, moderate volatility",
    expected: "Should predict weak uptrend (1)"
  },
  {
    features: [1.5, 1.5, 1.0],
    description: "Strong positive momentum, high volume, high volatility",
    expected: "Should predict strong uptrend (2)"
  }
]

puts "\n"
puts "=" * 70
puts "PREDICTIONS ON TEST SCENARIOS"
puts "=" * 70

test_scenarios.each_with_index do |scenario, idx|
  puts "\nScenario #{idx + 1}:"
  puts "  #{scenario[:description]}"
  puts "  Features: [x=#{scenario[:features][0]}, y=#{scenario[:features][1]}, z=#{scenario[:features][2]}]"
  puts "  #{scenario[:expected]}"
  puts

  posterior = predictor.predict(scenario[:features])

  # Show prediction
  puts "  Most Likely Outcome: #{posterior.max_outcome} (#{format('%.1f%%', posterior.probability(posterior.max_outcome) * 100)})"
  puts "  Confidence: #{format('%.1f%%', posterior.confidence * 100)}"
  puts "  Entropy: #{format('%.3f', posterior.entropy)} bits"
  puts

  puts "  Probability Distribution:"
  posterior.to_a.each do |outcome, prob|
    label = case outcome
            when -2 then "Strong downtrend"
            when -1 then "Weak downtrend"
            when 0 then "Neutral"
            when 1 then "Weak uptrend"
            when 2 then "Strong uptrend"
            end

    bar = "█" * (prob * 50).round
    puts "    #{outcome.to_s.rjust(2)}: #{format('%.3f', prob)} #{bar} #{label}"
  end

  puts "  " + ("-" * 68)
end

# Demonstrate uncertainty quantification via sampling
puts "\n"
puts "=" * 70
puts "UNCERTAINTY QUANTIFICATION VIA SAMPLING"
puts "=" * 70

ambiguous_scenario = [0.2, -0.3, 0.8]  # Slightly positive momentum, low volume, moderate volatility
puts "\nAmbiguous Scenario:"
puts "  Features: [x=#{ambiguous_scenario[0]}, y=#{ambiguous_scenario[1]}, z=#{ambiguous_scenario[2]}]"
puts "  (Slightly positive momentum with low volume - uncertain signal)\n\n"

posterior = predictor.predict(ambiguous_scenario)
puts posterior.summary

puts "\nGenerating 1000 samples from posterior..."
samples = posterior.samples(1000)
sample_dist = samples.tally.sort_by { |k, _v| k }

puts "\nSample Distribution:"
sample_dist.each do |outcome, count|
  percentage = (count / 10.0).round  # Scale to percentage
  bar = "▓" * (percentage / 2)
  puts "  #{outcome.to_s.rjust(2)}: #{count.to_s.rjust(4)} samples (#{percentage}%) #{bar}"
end

# Demonstrate prior update effect
puts "\n"
puts "=" * 70
puts "EFFECT OF PRIOR LEARNING"
puts "=" * 70

puts <<~HEREDOC

  Our predictor learns the prior distribution from training data.
  Let's compare predictions with learned prior vs. uniform prior:

HEREDOC

# Create predictor with uniform prior (no updating)
uniform_predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 0.8,
  update_prior: false  # Keep uniform prior
)
uniform_predictor.train_batch(training_data)

test_features = [0.5, 0.8, 0.5]
puts "Test features: #{test_features.inspect}"
puts "(Moderate positive signals)\n\n"

learned_posterior = predictor.predict(test_features)
uniform_posterior = uniform_predictor.predict(test_features)

puts <<~HEREDOC
  With Learned Prior:
    Most likely: #{learned_posterior.max_outcome} (#{format('%.1f%%', learned_posterior.probability(learned_posterior.max_outcome) * 100)})
    Confidence: #{format('%.1f%%', learned_posterior.confidence * 100)}
    Distribution: #{learned_posterior.to_h.map { |k, v| "#{k}:#{format('%.2f', v)}" }.join(', ')}

  With Uniform Prior:
    Most likely: #{uniform_posterior.max_outcome} (#{format('%.1f%%', uniform_posterior.probability(uniform_posterior.max_outcome) * 100)})
    Confidence: #{format('%.1f%%', uniform_posterior.confidence * 100)}
    Distribution: #{uniform_posterior.to_h.map { |k, v| "#{k}:#{format('%.2f', v)}" }.join(', ')}

HEREDOC

puts <<~HEREDOC
  Key Insights:
  =============
  1. The learned prior incorporates the base rate of outcomes in training data
  2. Predictions are full probability distributions, not just point estimates
  3. Confidence scores help identify uncertain predictions
  4. Entropy measures the uncertainty in the distribution
  5. Sampling provides Monte Carlo estimates for downstream analysis

  Applications:
  =============
  - Financial market prediction
  - Manufacturing quality control (defect severity prediction)
  - Health monitoring (patient condition assessment)
  - Weather forecasting (discrete condition categories)
  - Any domain with discrete outcomes and time series features

HEREDOC

debug_me "Final state"
