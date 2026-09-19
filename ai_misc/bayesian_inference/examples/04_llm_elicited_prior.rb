#!/usr/bin/env ruby
# frozen_string_literal: true

# Experiment 1: LLM-elicited priors
#
# The classic weakness of Bayesian analysis is "where does the prior
# come from?" — and the classic weakness of KDE-based likelihoods is
# that with only a handful of training observations, the posterior is
# mush. This experiment uses an LLM as a domain-knowledge oracle: it
# reads a natural-language market summary and emits a prior over trend
# outcomes {-2..2}, which then shapes predictions while data is scarce.
#
# Run:  ruby examples/04_llm_elicited_prior.rb
#
# Provider is auto-detected, local first: LM Studio (lms server start),
# then Apfel (apfel --serve), then cloud. Override with BI_LLM_PROVIDER
# (lms | apfel | cloud) and/or BI_LLM_MODEL.

require_relative 'common'

OUTCOMES = [-2, -1, 0, 1, 2].freeze

OUTCOME_DESCRIPTIONS = {
  -2 => 'strong downtrend',
  -1 => 'mild downtrend',
  0  => 'sideways / no trend',
  1  => 'mild uptrend',
  2  => 'strong uptrend'
}.freeze

MARKET_CONTEXT = <<~CONTEXT
  The Federal Reserve unexpectedly cut interest rates by 50 basis points
  yesterday. Tech-sector earnings this week broadly beat expectations.
  However, unemployment claims ticked up slightly and consumer sentiment
  is flat. Volatility (VIX) has dropped from 22 to 16 over five sessions.
CONTEXT

# Only a few historical observations — deliberately scarce, so the
# prior still matters. Features are [momentum, volume_z, volatility].
SPARSE_HISTORY = [
  { features: [0.8,  0.5, 0.9], outcome: 1 },
  { features: [-0.9, 0.2, 1.4], outcome: -1 },
  { features: [0.1, -0.1, 0.6], outcome: 0 },
  { features: [1.5,  1.1, 1.0], outcome: 2 },
  { features: [-0.2, 0.0, 0.7], outcome: 0 }
].freeze

# Ambiguous new reading: weak positive momentum, quiet volume
TODAY = [0.4, 0.2, 0.7].freeze

def build_predictor(prior_probabilities: nil)
  TimeSeriesPredictor.new(
    outcomes: OUTCOMES,
    bandwidth: 1.0,
    prior_probabilities: prior_probabilities,
    update_prior: false
  ).train_batch(SPARSE_HISTORY)
end

def report(title, posterior)
  puts <<~REPORT

    #{title}
    #{'-' * title.length}
    #{posterior}
    MAP outcome: #{posterior.max_outcome} (#{OUTCOME_DESCRIPTIONS[posterior.max_outcome]})
    Confidence:  #{format('%.1f%%', posterior.confidence * 100)}
    Entropy:     #{format('%.3f', posterior.entropy)} bits
  REPORT
end

puts <<~HEADER
  =====================================================================
  Experiment 1: LLM-elicited prior vs uniform prior (sparse data)
  =====================================================================

  Market context given to the LLM:
  #{MARKET_CONTEXT}
HEADER

elicitor = LlmPriorElicitor.new(
  outcomes: OUTCOMES,
  outcome_descriptions: OUTCOME_DESCRIPTIONS
)

llm_prior = elicitor.elicit(MARKET_CONTEXT)

puts "LLM-elicited prior: #{llm_prior}"
puts "Prior entropy: #{format('%.3f', llm_prior.entropy)} bits " \
     "(uniform would be #{format('%.3f', Math.log2(OUTCOMES.size))})"

uniform_posterior = build_predictor.predict(TODAY)
informed_posterior = build_predictor(prior_probabilities: llm_prior.probabilities).predict(TODAY)

report('With UNIFORM prior (data only)', uniform_posterior)
report('With LLM-ELICITED prior (knowledge + data)', informed_posterior)

puts <<~FOOTER

  Information gained from the LLM prior:
    KL(informed || uniform-posterior basis) shift in MAP/confidence above.
    With only #{SPARSE_HISTORY.size} training observations, the prior visibly
    steers the posterior. As real observations accumulate, the KDE
    likelihood will dominate and the two posteriors will converge —
    which is exactly the behavior you want.
FOOTER
