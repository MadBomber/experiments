#!/usr/bin/env ruby
# frozen_string_literal: true

# Experiment 2: LLM as likelihood function, Ruby as Bayes engine
#
# LLMs judge semantic evidence well ("how surprising is this log line
# if the database were the problem?") but combine probabilities badly:
# ask one to accumulate five pieces of evidence in a single chat and it
# anchors, double-counts, and drifts. So we split the job:
#
#   LLM:  one independent judgment per (evidence, hypothesis) pair
#   Ruby: posterior_n = normalize(likelihood_n * posterior_{n-1})
#
# The scenario: a production outage with three candidate root causes.
# Evidence arrives one item at a time; watch the posterior evolve.
#
# Run:  ruby examples/05_llm_likelihood_diagnosis.rb
#
# Provider is auto-detected, local first: LM Studio (lms server start),
# then Apfel (apfel --serve), then cloud. Override with BI_LLM_PROVIDER
# (lms | apfel | cloud) and/or BI_LLM_MODEL.

require_relative 'common'

HYPOTHESES = {
  bad_deploy: 'The 14:02 application deploy introduced a defect',
  database:   'The primary PostgreSQL instance is degraded',
  network:    'There is a network partition between availability zones'
}.freeze

EVIDENCE_STREAM = [
  'HTTP 500 error rate jumped from 0.1% to 8% at 14:04, two minutes after the deploy finished.',
  'Database CPU, connections, and replication lag are all normal per the Postgres dashboard.',
  'Rolling back the deploy at 14:20 did NOT reduce the error rate.',
  'Cross-AZ ping times spiked from 1ms to 900ms starting at 14:03.',
  'The cloud provider posted a networking incident for our region at 14:35.'
].freeze

def bar(probability, width: 30)
  filled = (probability * width).round
  ('#' * filled).ljust(width, '.')
end

def print_distribution(prior)
  HYPOTHESES.each_key do |id|
    p = prior.probability(id)
    puts format('    %-12s %s %5.1f%%', id, bar(p), p * 100)
  end
end

puts <<~HEADER
  =====================================================================
  Experiment 2: Sequential Bayesian diagnosis with LLM likelihoods
  =====================================================================
  Hypotheses:
  #{HYPOTHESES.map { |id, desc| "  - #{id}: #{desc}" }.join("\n")}

  Starting from a uniform prior. Evidence arrives one item at a time;
  the LLM judges P(evidence | hypothesis), Ruby applies Bayes' theorem.
HEADER

estimator = LlmLikelihoodEstimator.new(hypotheses: HYPOTHESES)
belief = Prior.new(HYPOTHESES.keys)

puts "\n  Initial belief:"
print_distribution(belief)

EVIDENCE_STREAM.each_with_index do |evidence, i|
  likelihoods = estimator.likelihoods(evidence)
  posterior = Posterior.new(belief, likelihoods)

  puts <<~STEP

    Evidence #{i + 1}: #{evidence}
      LLM likelihoods P(e|H): #{likelihoods.map { |k, v| "#{k}=#{format('%.2f', v)}" }.join(', ')}
      Information gain: #{format('%.3f', posterior.kl_divergence_from_prior)} bits
  STEP
  print_distribution(posterior_prior = Prior.new(HYPOTHESES.keys, posterior.to_h))

  belief = posterior_prior
end

winner = belief.probabilities.max_by { |_, p| p }

puts <<~FOOTER

  =====================================================================
  Final diagnosis: #{winner.first} at #{format('%.1f%%', winner.last * 100)} confidence
  (#{HYPOTHESES[winner.first]})

  Note the arc: evidence 1 looks damning for the deploy, but Bayes
  never fully commits (likelihoods are clamped away from 0 and 1), so
  evidence 3-5 can cleanly reverse the belief. A single LLM asked to
  track all of this in prose typically anchors on its first conclusion.
  =====================================================================
FOOTER
