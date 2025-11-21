# frozen_string_literal: true

require "test_helper"

class BayesianInferenceTest < Minitest::Test
  def test_version_is_defined
    refute_nil ::BayesianInference::VERSION
  end

  def test_convenience_method
    predictor = BayesianInference.predictor(outcomes: [0, 1], bandwidth: 1.0)
    assert_instance_of BayesianInference::TimeSeriesPredictor, predictor
  end
end

class PriorTest < Minitest::Test
  def setup
    @outcomes = [-2, -1, 0, 1, 2]
  end

  def test_uniform_prior
    prior = BayesianInference::Prior.new(@outcomes)

    # Each outcome should have equal probability
    assert_in_delta 0.2, prior.probability(-2), 0.001
    assert_in_delta 0.2, prior.probability(0), 0.001
    assert_in_delta 0.2, prior.probability(2), 0.001
  end

  def test_custom_prior
    probs = {-2 => 0.1, -1 => 0.2, 0 => 0.4, 1 => 0.2, 2 => 0.1}
    prior = BayesianInference::Prior.new(@outcomes, probs)

    assert_in_delta 0.1, prior.probability(-2), 0.001
    assert_in_delta 0.4, prior.probability(0), 0.001
    assert_in_delta 0.1, prior.probability(2), 0.001
  end

  def test_invalid_probabilities_sum
    probs = {-2 => 0.1, -1 => 0.2, 0 => 0.4, 1 => 0.2, 2 => 0.2}  # Sum > 1
    assert_raises(ArgumentError) do
      BayesianInference::Prior.new(@outcomes, probs)
    end
  end

  def test_update_from_observations
    prior = BayesianInference::Prior.new(@outcomes)
    observations = {-2 => 5, -1 => 10, 0 => 30, 1 => 10, 2 => 5}

    updated = prior.update_from_observations(observations)

    # Outcome 0 should have highest probability
    assert updated.probability(0) > updated.probability(-2)
    assert updated.probability(0) > updated.probability(2)
  end

  def test_entropy
    # Uniform prior should have maximum entropy
    uniform = BayesianInference::Prior.new(@outcomes)
    max_entropy = Math.log2(@outcomes.size)
    assert_in_delta max_entropy, uniform.entropy, 0.001

    # Peaked prior should have lower entropy
    peaked = BayesianInference::Prior.new(@outcomes, {-2 => 0.0, -1 => 0.0, 0 => 1.0, 1 => 0.0, 2 => 0.0})
    assert_in_delta 0.0, peaked.entropy, 0.001
  end

  def test_combine_priors
    prior1 = BayesianInference::Prior.new(@outcomes, {-2 => 0.1, -1 => 0.2, 0 => 0.4, 1 => 0.2, 2 => 0.1})
    prior2 = BayesianInference::Prior.new(@outcomes, {-2 => 0.3, -1 => 0.2, 0 => 0.0, 1 => 0.2, 2 => 0.3})

    combined = prior1.combine(prior2, weight: 0.5)

    # Should be average of the two
    assert_in_delta 0.2, combined.probability(-2), 0.001
    assert_in_delta 0.2, combined.probability(0), 0.001
  end
end

class LikelihoodTest < Minitest::Test
  def setup
    @observations = [
      {features: [1.0, 2.0], outcome: 1},
      {features: [1.1, 2.1], outcome: 1},
      {features: [-1.0, -2.0], outcome: -1}
    ]
    @likelihood = BayesianInference::Likelihood.new(@observations, bandwidth: 1.0)
  end

  def test_initialization
    assert_equal 3, @likelihood.size
    refute @likelihood.empty?
  end

  def test_add_observation
    likelihood = BayesianInference::Likelihood.new([], bandwidth: 1.0)
    assert likelihood.empty?

    likelihood.add_observation([1.0, 2.0], 1)
    refute likelihood.empty?
    assert_equal 1, likelihood.size
  end

  def test_compute_likelihoods
    likelihoods = @likelihood.compute([1.0, 2.0], [-1, 0, 1])

    # Should be hash with all outcomes
    assert_equal 3, likelihoods.size
    assert likelihoods.key?(-1)
    assert likelihoods.key?(1)

    # Sum should be 1 (normalized)
    assert_in_delta 1.0, likelihoods.values.sum, 0.001

    # Likelihood for outcome 1 should be higher (closer to observations)
    assert likelihoods[1] > likelihoods[-1]
  end

  def test_estimate_density
    # Features close to outcome 1 observations
    density_1 = @likelihood.estimate_density([1.05, 2.05], 1)
    density_minus1 = @likelihood.estimate_density([1.05, 2.05], -1)

    # Should be higher for outcome 1
    assert density_1 > density_minus1
  end

  def test_outcome_counts
    counts = @likelihood.outcome_counts
    assert_equal 2, counts[1]
    assert_equal 1, counts[-1]
  end

  def test_empty_likelihood
    likelihood = BayesianInference::Likelihood.new([], bandwidth: 1.0)
    likelihoods = likelihood.compute([1.0, 2.0], [-1, 0, 1])

    # Should return uniform when no data
    assert_in_delta 1.0/3, likelihoods[-1], 0.001
    assert_in_delta 1.0/3, likelihoods[0], 0.001
    assert_in_delta 1.0/3, likelihoods[1], 0.001
  end
end

class PosteriorTest < Minitest::Test
  def setup
    @outcomes = [-2, -1, 0, 1, 2]
    @prior = BayesianInference::Prior.new(@outcomes)
    @likelihoods = {-2 => 0.05, -1 => 0.1, 0 => 0.15, 1 => 0.6, 2 => 0.1}
    @posterior = BayesianInference::Posterior.new(@prior, @likelihoods)
  end

  def test_initialization
    assert_instance_of BayesianInference::Posterior, @posterior
    refute_nil @posterior.probabilities
  end

  def test_probabilities_sum_to_one
    sum = @posterior.probabilities.values.sum
    assert_in_delta 1.0, sum, 0.001
  end

  def test_max_outcome
    # Outcome 1 has highest likelihood
    assert_equal 1, @posterior.max_outcome
  end

  def test_top_outcomes
    top = @posterior.top_outcomes(3)
    assert_equal 3, top.size

    # First should be outcome 1
    assert_equal 1, top[0][0]

    # Probabilities should be descending
    assert top[0][1] >= top[1][1]
    assert top[1][1] >= top[2][1]
  end

  def test_entropy
    entropy = @posterior.entropy
    assert entropy >= 0
    assert entropy <= Math.log2(@outcomes.size)
  end

  def test_confidence
    confidence = @posterior.confidence
    assert confidence >= 0
    assert confidence <= 1
  end

  def test_kl_divergence
    kl = @posterior.kl_divergence_from_prior
    assert kl >= 0  # KL divergence is always non-negative
  end

  def test_sampling
    # Sample should return valid outcome
    sample = @posterior.sample
    assert @outcomes.include?(sample)

    # Multiple samples should follow distribution
    samples = @posterior.samples(1000)
    assert_equal 1000, samples.size

    # Most common sample should be max_outcome (with high probability)
    sample_counts = samples.tally
    most_common = sample_counts.max_by { |_k, v| v }[0]
    assert_equal @posterior.max_outcome, most_common
  end

  def test_to_h_and_to_a
    hash = @posterior.to_h
    assert_instance_of Hash, hash
    assert_equal @outcomes.size, hash.size

    array = @posterior.to_a
    assert_instance_of Array, array
    assert_equal @outcomes.size, array.size
  end
end

class TimeSeriesPredictorTest < Minitest::Test
  def setup
    @predictor = BayesianInference::TimeSeriesPredictor.new(
      outcomes: [-2, -1, 0, 1, 2],
      bandwidth: 1.0
    )
  end

  def test_initialization
    assert_equal [-2, -1, 0, 1, 2], @predictor.outcomes
    refute @predictor.trained?
  end

  def test_train
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)
    assert @predictor.trained?
    assert_equal 1, @predictor.training_size
  end

  def test_train_batch
    observations = [
      {features: [1.0, 2.0, 3.0], outcome: 1},
      {features: [1.1, 2.1, 2.9], outcome: 1},
      {features: [-1.0, -2.0, 0.5], outcome: -2}
    ]

    @predictor.train_batch(observations)
    assert_equal 3, @predictor.training_size
  end

  def test_predict
    # Train with some data
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)
    @predictor.train([1.1, 2.1, 2.9], outcome: 1)
    @predictor.train([-1.0, -2.0, 0.5], outcome: -2)

    # Predict
    posterior = @predictor.predict([1.0, 2.0, 3.0])
    assert_instance_of BayesianInference::Posterior, posterior

    # Should predict outcome 1 with high probability
    assert_equal 1, posterior.max_outcome
  end

  def test_predict_outcome
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)
    @predictor.train([1.1, 2.1, 2.9], outcome: 1)

    outcome = @predictor.predict_outcome([1.0, 2.0, 3.0])
    assert_equal 1, outcome
  end

  def test_predict_proba
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)

    proba = @predictor.predict_proba([1.0, 2.0, 3.0])
    assert_instance_of Hash, proba
    assert_in_delta 1.0, proba.values.sum, 0.001
  end

  def test_feature_dimension_validation
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)

    # Should raise error for different dimension
    assert_raises(ArgumentError) do
      @predictor.train([1.0, 2.0], outcome: 1)
    end

    assert_raises(ArgumentError) do
      @predictor.predict([1.0, 2.0])
    end
  end

  def test_outcome_validation
    assert_raises(ArgumentError) do
      @predictor.train([1.0, 2.0, 3.0], outcome: 99)  # Invalid outcome
    end
  end

  def test_reset
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)
    assert @predictor.trained?

    @predictor.reset!
    refute @predictor.trained?
    assert_equal 0, @predictor.training_size
  end

  def test_bandwidth_update
    @predictor.bandwidth = 2.0
    assert_equal 2.0, @predictor.bandwidth
  end

  def test_training_distribution
    @predictor.train([1.0, 2.0, 3.0], outcome: 1)
    @predictor.train([1.1, 2.1, 2.9], outcome: 1)
    @predictor.train([-1.0, -2.0, 0.5], outcome: -2)

    dist = @predictor.training_distribution
    assert_equal 2, dist[1]
    assert_equal 1, dist[-2]
  end

  def test_prior_update
    # Create predictor with prior updating enabled
    predictor = BayesianInference::TimeSeriesPredictor.new(
      outcomes: [-2, -1, 0, 1, 2],
      bandwidth: 1.0,
      update_prior: true
    )

    # Train with skewed data
    10.times { predictor.train([1.0, 2.0, 3.0], outcome: 1) }
    2.times { predictor.train([-1.0, -2.0, 0.5], outcome: -2) }

    # Prior should reflect the skew
    assert predictor.prior.probability(1) > predictor.prior.probability(-2)
  end
end
