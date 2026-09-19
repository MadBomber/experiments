# frozen_string_literal: true

require_relative 'test_helper'

class LlmLikelihoodEstimatorTest < Minitest::Test
  include BayesianInference

  HYPOTHESES = {
    bad_deploy: 'The 14:02 deploy introduced a bug',
    database:   'The primary database is degraded',
    network:    'There is a network partition'
  }.freeze

  def estimator_with(content)
    LlmLikelihoodEstimator.new(hypotheses: HYPOTHESES, chat: FakeChat.new(content))
  end

  def test_likelihoods_returns_clamped_values_per_hypothesis
    estimator = estimator_with('{"bad_deploy": 0.9, "database": 0.2, "network": 1.0}')
    lh = estimator.likelihoods('error rate spiked after deploy')

    assert_equal HYPOTHESES.keys.sort, lh.keys.sort
    assert_in_delta 0.9, lh[:bad_deploy], 1e-9
    assert_equal 0.999, lh[:network], 'certainty must be clamped'
  end

  def test_missing_hypothesis_gets_floor_not_zero
    lh = estimator_with('{"bad_deploy": 0.7}').likelihoods('partial answer')
    assert_equal 0.001, lh[:database]
  end

  def test_sequential_bayes_updates_chain_through_prior_and_posterior
    prior = Prior.new(HYPOTHESES.keys)

    # Two pieces of evidence, both pointing at the deploy
    [
      { bad_deploy: 0.9, database: 0.3, network: 0.2 },
      { bad_deploy: 0.8, database: 0.4, network: 0.1 }
    ].each do |lh|
      posterior = Posterior.new(prior, lh)
      prior = Prior.new(HYPOTHESES.keys, posterior.to_h)
    end

    assert_equal :bad_deploy, prior.probabilities.max_by { |_, p| p }.first
    assert prior.probability(:bad_deploy) > 0.7
    assert_in_delta 1.0, prior.probabilities.values.sum, 1e-6
  end

  def test_prompt_includes_evidence_and_hypothesis_descriptions
    estimator = estimator_with('{"bad_deploy": 0.5, "database": 0.5, "network": 0.5}')
    estimator.likelihoods('DB CPU is normal')

    prompt = estimator.instance_variable_get(:@chat).last_prompt
    assert_includes prompt, 'DB CPU is normal'
    assert_includes prompt, 'bad_deploy: The 14:02 deploy introduced a bug'
  end

  def test_likelihoods_from_response_is_pure_and_testable_without_chat
    estimator = LlmLikelihoodEstimator.new(hypotheses: HYPOTHESES, chat: :unused)
    lh = estimator.likelihoods_from_response('{"bad_deploy": 0.6, "database": 0.1, "network": 0.05}')
    assert_in_delta 0.6, lh[:bad_deploy], 1e-9
  end
end
