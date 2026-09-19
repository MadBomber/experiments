#!/usr/bin/env ruby
# frozen_string_literal: true

# Coin Flip Example: Bayesian Inference for Estimating Coin Bias
#
# Given a sequence of coin flips, what's the probability distribution
# over different coin biases? We model this as predicting discrete
# "bias levels" from a single feature: the proportion of heads seen.

require_relative 'common'

BIAS_LABELS = {
  -2 => 'Heavily tails',
  -1 => 'Leans tails',
  0  => 'Fair coin',
  1  => 'Leans heads',
  2  => 'Heavily heads'
}.freeze

puts UI.banner('Bayesian Coin Flip Bias Estimation',
               'How biased is this coin?')

puts <<~HEREDOC

  We flip a coin of unknown bias many times, then ask: which of five
  bias levels best explains what we saw? Each flip sequence is reduced
  to one feature — the proportion of heads.

HEREDOC

puts UI.section('Bias Levels')
BIAS_LABELS.each do |level, label|
  puts UI.kv(level.to_s.rjust(2), label, label_width: 3, indent: 4)
end

# ----------------------------------------------------------------------
puts UI.section('Training')

predictor = BayesianInference.predictor(
  outcomes: BIAS_LABELS.keys,
  bandwidth: 0.1 # narrow kernel: the heads-proportion feature only spans 0..1
)

# Synthetic training data: coins with known biases, each contributing
# a heads-proportion drawn from its characteristic range
TRAINING_PLAN = [
  { outcome: -2, count: 10, heads_range: 0.0..0.2 },
  { outcome: -1, count: 15, heads_range: 0.2..0.4 },
  { outcome: 0,  count: 20, heads_range: 0.4..0.6 },
  { outcome: 1,  count: 15, heads_range: 0.6..0.8 },
  { outcome: 2,  count: 10, heads_range: 0.8..1.0 }
].freeze

training_data = TRAINING_PLAN.flat_map do |plan|
  Array.new(plan[:count]) do
    { features: [rand(plan[:heads_range])], outcome: plan[:outcome] }
  end
end

predictor.train_batch(training_data.shuffle)

puts "  Simulated coins with known biases:\n\n"
TRAINING_PLAN.each do |plan|
  range = "#{(plan[:heads_range].begin * 100).to_i}–#{(plan[:heads_range].end * 100).to_i}% heads"
  puts "  #{plan[:outcome].to_s.rjust(3)}  #{BIAS_LABELS[plan[:outcome]].ljust(14)} " \
       "#{plan[:count]} sequences, #{range}"
end
puts
puts UI.kv('Observations', predictor.training_size)
puts UI.kv('Bandwidth', predictor.bandwidth)

# ----------------------------------------------------------------------
puts UI.section('Predictions')

test_cases = [
  { heads: 0.1, expected: -2 },
  { heads: 0.3, expected: -1 },
  { heads: 0.5, expected: 0 },
  { heads: 0.7, expected: 1 },
  { heads: 0.9, expected: 2 }
]

test_cases.each do |test|
  posterior = predictor.predict([test[:heads]])
  predicted = posterior.max_outcome

  puts "\n  A coin showing #{(test[:heads] * 100).to_i}% heads   " \
       "#{UI.verdict(predicted, test[:expected])}\n\n"
  puts UI.posterior_panel(posterior, labels: BIAS_LABELS)
  puts
end

# ----------------------------------------------------------------------
puts UI.section('Sampling from the Posterior')

test_heads = 0.65
posterior = predictor.predict([test_heads])

puts <<~HEREDOC

  For a coin showing #{(test_heads * 100).to_i}% heads, drawing 100 samples from the
  posterior shows how belief is spread across the bias levels:

HEREDOC

puts UI.tally_chart(posterior.samples(100), labels: BIAS_LABELS)

# ----------------------------------------------------------------------
puts UI.section('Key Insights')

puts UI.bullet_list('What this demo shows:', [
  'The posterior distribution is our updated belief after seeing data',
  'Confidence is higher (entropy lower) away from category boundaries',
  'The prior is learned from the training data distribution',
  'Sampling from the posterior quantifies the remaining uncertainty'
])
puts
