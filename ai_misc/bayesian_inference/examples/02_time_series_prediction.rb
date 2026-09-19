#!/usr/bin/env ruby
# frozen_string_literal: true

# Time Series Prediction Example: Bayesian Inference for Discrete Outcomes
#
# The core use case: predict a probability distribution over 5 discrete
# outcomes {-2, -1, 0, 1, 2} given three time series features.
#
# Scenario: market trend prediction
#   x: price momentum, y: volume indicator, z: volatility measure
#   outcome: next period's trend direction

require_relative 'common'

TREND_LABELS = {
  -2 => 'Strong downtrend',
  -1 => 'Weak downtrend',
  0  => 'Neutral/sideways',
  1  => 'Weak uptrend',
  2  => 'Strong uptrend'
}.freeze

def features_line(features)
  x, y, z = features
  "x=#{x} (momentum)  y=#{y} (volume)  z=#{z} (volatility)"
end

puts UI.banner('Bayesian Time Series Prediction',
               'Market trend from momentum, volume, and volatility')

puts <<~HEREDOC

  Given three normalized indicators — price momentum (x), volume (y),
  and volatility (z) — predict a full probability distribution over
  next period's trend:

HEREDOC

TREND_LABELS.each do |level, label|
  puts UI.kv(level.to_s.rjust(2), label, label_width: 3, indent: 4)
end

# ----------------------------------------------------------------------
puts UI.section('Training')

predictor = BayesianInference.predictor(
  outcomes: TREND_LABELS.keys,
  bandwidth: 0.8,     # moderate bandwidth for time series
  update_prior: true  # learn prior from observations
)

# Synthetic training data: characteristic feature ranges per outcome
TRAINING_PLAN = [
  { outcome: -2, count: 30, x: -2.0..-1.0, y: -1.0..0.5, z: 0.5..2.0 },
  { outcome: -1, count: 40, x: -1.0..-0.3, y: -0.5..1.0, z: 0.0..1.0 },
  { outcome: 0,  count: 50, x: -0.3..0.3,  y: -1.0..1.0, z: 0.0..0.8 },
  { outcome: 1,  count: 40, x: 0.3..1.0,   y: -0.5..1.5, z: 0.0..1.0 },
  { outcome: 2,  count: 30, x: 1.0..2.0,   y: 0.5..2.0,  z: 0.5..1.5 }
].freeze

training_data = TRAINING_PLAN.flat_map do |plan|
  Array.new(plan[:count]) do
    { features: [rand(plan[:x]), rand(plan[:y]), rand(plan[:z])],
      outcome: plan[:outcome] }
  end
end

predictor.train_batch(training_data.shuffle)

puts "  Simulated market regimes:\n\n"
TRAINING_PLAN.each do |plan|
  puts "  #{plan[:outcome].to_s.rjust(3)}  #{TREND_LABELS[plan[:outcome]].ljust(18)} #{plan[:count]} observations"
end
puts
puts UI.kv('Observations', predictor.training_size)
puts UI.kv('Bandwidth', predictor.bandwidth)
puts UI.kv('Prior', 'learned from data')

# ----------------------------------------------------------------------
puts UI.section('Predictions on Test Scenarios')

test_scenarios = [
  { features: [-1.5, 0.2, 1.2], expected: -2,
    description: 'Strong negative momentum, low volume, high volatility' },
  { features: [-0.5, 0.5, 0.5], expected: -1,
    description: 'Weak negative momentum, moderate volume and volatility' },
  { features: [0.0, 0.0, 0.3], expected: 0,
    description: 'Zero momentum, low volume, low volatility' },
  { features: [0.7, 1.0, 0.6], expected: 1,
    description: 'Positive momentum, high volume, moderate volatility' },
  { features: [1.5, 1.5, 1.0], expected: 2,
    description: 'Strong positive momentum, high volume, high volatility' }
]

test_scenarios.each_with_index do |scenario, idx|
  posterior = predictor.predict(scenario[:features])
  predicted = posterior.max_outcome

  puts "\n  #{UI.paint("Scenario #{idx + 1}:", :bold)} #{scenario[:description]}"
  puts "  #{UI.note(features_line(scenario[:features]))}"
  puts "  #{UI.verdict(predicted, scenario[:expected])}\n\n"
  puts UI.posterior_panel(posterior, labels: TREND_LABELS)
  puts
end

# ----------------------------------------------------------------------
puts UI.section('Uncertainty Quantification via Sampling')

ambiguous = [0.2, -0.3, 0.8]

puts <<~HEREDOC

  An ambiguous scenario — slightly positive momentum on low volume:
    #{features_line(ambiguous)}

HEREDOC

posterior = predictor.predict(ambiguous)
puts UI.posterior_stats(posterior, labels: TREND_LABELS)
puts "\n  Drawing 1000 samples from this posterior:\n\n"
puts UI.tally_chart(posterior.samples(1000), labels: TREND_LABELS)

# ----------------------------------------------------------------------
puts UI.section('Effect of Prior Learning')

puts <<~HEREDOC

  The predictor above learned its prior from the training data. Compare
  its prediction against an identical predictor kept on a uniform prior:

HEREDOC

uniform_predictor = BayesianInference.predictor(
  outcomes: TREND_LABELS.keys,
  bandwidth: 0.8,
  update_prior: false
)
uniform_predictor.train_batch(training_data)

test_features = [0.5, 0.8, 0.5]
puts "  Test scenario #{UI.note('(moderate positive signals)')}:"
puts "  #{UI.note(features_line(test_features))}\n\n"

{
  'With learned prior' => predictor.predict(test_features),
  'With uniform prior' => uniform_predictor.predict(test_features)
}.each do |title, post|
  puts "  #{UI.paint(title, :bold)}"
  puts UI.distribution(post.to_a, labels: TREND_LABELS)
  puts UI.kv('Confidence', UI.pct(post.confidence).strip)
  puts
end

# ----------------------------------------------------------------------
puts UI.section('Key Insights')

puts UI.bullet_list('What this demo shows:', [
  'The learned prior bakes in the base rate of each outcome',
  'Predictions are full probability distributions, not point estimates',
  'Confidence scores flag uncertain predictions',
  'Entropy measures how spread out the distribution is',
  'Sampling provides Monte Carlo estimates for downstream analysis'
])
puts
puts UI.bullet_list('Where this applies:', [
  'Financial market prediction',
  'Manufacturing quality control (defect severity)',
  'Health monitoring (patient condition categories)',
  'Weather forecasting (discrete condition categories)',
  'Any domain with discrete outcomes and time series features'
])
puts
