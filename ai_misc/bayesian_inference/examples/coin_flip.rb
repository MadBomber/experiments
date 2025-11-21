#!/usr/bin/env ruby
# frozen_string_literal: true

# Coin Flip Example: Bayesian Inference for Estimating Coin Bias
#
# This example demonstrates Bayesian inference for a simple problem:
# Given a sequence of coin flips, what's the probability distribution
# over different coin biases?
#
# We model this as predicting discrete "bias levels" from flip sequences.

require_relative '../lib/bayesian_inference'
require 'debug_me'
include DebugMe

puts <<~HEREDOC
  =====================================
  Bayesian Coin Flip Bias Estimation
  =====================================

  Problem: We have a coin with unknown bias. After observing flips,
  we want to estimate the bias level as one of:
    -2: Very biased toward tails
    -1: Slightly biased toward tails
     0: Fair coin
     1: Slightly biased toward heads
     2: Very biased toward heads

  We represent each flip sequence as a feature: [proportion of heads]

HEREDOC

# Create predictor for bias levels
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 0.3  # Small bandwidth for precise estimation
)

debug_me "Initial predictor state"

# Generate synthetic training data
# We'll simulate coins with different biases
puts "Generating training data from coins with known biases...\n\n"

training_data = []

# Very biased toward tails (bias = -2)
10.times do
  heads_proportion = rand(0.0..0.2)  # 0-20% heads
  training_data << {features: [heads_proportion], outcome: -2}
end

# Slightly biased toward tails (bias = -1)
15.times do
  heads_proportion = rand(0.2..0.4)  # 20-40% heads
  training_data << {features: [heads_proportion], outcome: -1}
end

# Fair coin (bias = 0)
20.times do
  heads_proportion = rand(0.4..0.6)  # 40-60% heads
  training_data << {features: [heads_proportion], outcome: 0}
end

# Slightly biased toward heads (bias = 1)
15.times do
  heads_proportion = rand(0.6..0.8)  # 60-80% heads
  training_data << {features: [heads_proportion], outcome: 1}
end

# Very biased toward heads (bias = 2)
10.times do
  heads_proportion = rand(0.8..1.0)  # 80-100% heads
  training_data << {features: [heads_proportion], outcome: 2}
end

# Shuffle and train
training_data.shuffle!
predictor.train_batch(training_data)

puts "Trained with #{predictor.training_size} observations"
puts predictor.summary
puts "\n"

# Now test with new observations
test_cases = [
  {features: [0.1], description: "10% heads (very biased toward tails)"},
  {features: [0.3], description: "30% heads (slightly biased toward tails)"},
  {features: [0.5], description: "50% heads (fair coin)"},
  {features: [0.7], description: "70% heads (slightly biased toward heads)"},
  {features: [0.9], description: "90% heads (very biased toward heads)"}
]

puts "=" * 60
puts "PREDICTIONS"
puts "=" * 60

test_cases.each do |test|
  posterior = predictor.predict(test[:features])

  puts <<~HEREDOC

    Test: #{test[:description]}
    Features: #{test[:features].inspect}

    #{posterior.summary}

    Top 3 Most Likely Biases:
  HEREDOC

  posterior.top_outcomes(3).each_with_index do |(outcome, prob), idx|
    bias_label = case outcome
                 when -2 then "Very biased toward tails"
                 when -1 then "Slightly biased toward tails"
                 when 0 then "Fair coin"
                 when 1 then "Slightly biased toward heads"
                 when 2 then "Very biased toward heads"
                 end

    puts "    #{idx + 1}. Bias #{outcome} (#{bias_label}): #{format('%.1f%%', prob * 100)}"
  end

  puts "    " + ("-" * 50)
end

# Demonstrate sampling from posterior
puts "\n" + "=" * 60
puts "SAMPLING FROM POSTERIOR"
puts "=" * 60

test_feature = [0.65]  # Slightly biased toward heads
posterior = predictor.predict(test_feature)

puts "\nFor a coin showing #{(test_feature[0] * 100).to_i}% heads:"
puts "Generating 100 samples from posterior distribution...\n\n"

samples = posterior.samples(100)
sample_counts = samples.tally.sort_by { |k, _v| k }

sample_counts.each do |outcome, count|
  bar = "#" * (count / 2)  # Scale down for display
  puts "  Bias #{outcome}: #{count} samples #{bar}"
end

puts <<~HEREDOC


  Key Insights:
  =============
  1. The posterior distribution shows our updated beliefs after seeing data
  2. Higher confidence (lower entropy) when observations are far from boundaries
  3. The prior is learned from the training data distribution
  4. Sampling from the posterior gives us uncertainty quantification

HEREDOC

debug_me "Final predictor state"
