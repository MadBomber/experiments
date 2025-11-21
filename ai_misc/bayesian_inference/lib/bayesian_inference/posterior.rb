# frozen_string_literal: true

module BayesianInference
  # Computes posterior probability distribution using Bayes' theorem
  #
  # Bayes' Theorem: P(outcome | data) ∝ P(data | outcome) × P(outcome)
  #
  # The Posterior class combines prior beliefs and observed data likelihoods
  # to produce an updated probability distribution over outcomes.
  class Posterior
    attr_reader :prior, :likelihoods, :probabilities

    # Initialize posterior distribution
    #
    # @param prior [Prior] Prior probability distribution
    # @param likelihoods [Hash] Likelihood values {outcome => P(data|outcome)}
    #
    # @example
    #   prior = Prior.new([-2, -1, 0, 1, 2])
    #   likelihoods = {-2 => 0.05, -1 => 0.1, 0 => 0.15, 1 => 0.6, 2 => 0.1}
    #   posterior = Posterior.new(prior, likelihoods)
    def initialize(prior, likelihoods)
      @prior = prior
      @likelihoods = likelihoods
      @probabilities = compute_posterior
      debug_me("Computed Posterior") { %i[@likelihoods @probabilities] }
    end

    # Get posterior probability for specific outcome
    #
    # @param outcome [Numeric] The outcome to query
    # @return [Float] Posterior probability
    def probability(outcome)
      @probabilities[outcome] || 0.0
    end
    alias_method :[], :probability

    # Get the most likely outcome (MAP estimate)
    #
    # @return [Numeric] Outcome with highest posterior probability
    def max_outcome
      @probabilities.max_by { |_outcome, prob| prob }&.first
    end

    # Get top N most likely outcomes
    #
    # @param n [Integer] Number of outcomes to return
    # @return [Array<Array>] Array of [outcome, probability] sorted by probability
    #
    # @example
    #   posterior.top_outcomes(3)
    #   # => [[1, 0.6], [0, 0.15], [-1, 0.1]]
    def top_outcomes(n = 3)
      @probabilities.sort_by { |_outcome, prob| -prob }.take(n)
    end

    # Get probability distribution as sorted array
    #
    # @return [Array<Array>] Array of [outcome, probability] sorted by outcome
    def to_a
      @probabilities.sort_by { |outcome, _prob| outcome }
    end

    # Get probability distribution as hash
    #
    # @return [Hash] {outcome => probability}
    def to_h
      @probabilities.dup
    end

    # Compute entropy of posterior distribution
    # Higher entropy = more uncertain, Lower entropy = more confident
    #
    # @return [Float] Shannon entropy in bits
    def entropy
      -@probabilities.values.reduce(0.0) do |sum, prob|
        sum + (prob > 0 ? prob * Math.log2(prob) : 0)
      end
    end

    # Compute Kullback-Leibler divergence from prior to posterior
    # Measures information gain from observing data
    #
    # @return [Float] KL divergence in bits (always non-negative)
    def kl_divergence_from_prior
      @probabilities.reduce(0.0) do |sum, (outcome, posterior_prob)|
        prior_prob = @prior.probability(outcome)
        if posterior_prob > 0 && prior_prob > 0
          sum + posterior_prob * Math.log2(posterior_prob / prior_prob)
        else
          sum
        end
      end
    end

    # Get confidence level (1 - entropy / max_entropy)
    # Returns value between 0 (uniform, no confidence) and 1 (certain)
    #
    # @return [Float] Confidence level
    def confidence
      max_entropy = Math.log2(@probabilities.size)
      1.0 - (entropy / max_entropy)
    end

    # Sample an outcome from the posterior distribution
    #
    # @param rng [Random] Random number generator
    # @return [Numeric] Sampled outcome
    def sample(rng: Random.new)
      cumulative = 0.0
      threshold = rng.rand

      @probabilities.each do |outcome, prob|
        cumulative += prob
        return outcome if cumulative >= threshold
      end

      # Fallback (shouldn't reach here if probabilities sum to 1)
      @probabilities.keys.last
    end

    # Generate N samples from the posterior distribution
    #
    # @param n [Integer] Number of samples
    # @param rng [Random] Random number generator
    # @return [Array] Array of sampled outcomes
    def samples(n, rng: Random.new)
      Array.new(n) { sample(rng: rng) }
    end

    # Return formatted string representation
    #
    # @return [String] Formatted probability distribution
    def to_s
      parts = @probabilities.sort.map do |outcome, prob|
        "#{outcome}: #{format('%.3f', prob)}"
      end
      "Posterior(#{parts.join(', ')})"
    end

    # Return detailed summary with statistics
    #
    # @return [String] Multi-line summary
    def summary
      max_out = max_outcome
      max_prob = probability(max_out)

      <<~SUMMARY
        Posterior Distribution Summary:
        ================================
        Most Likely: #{max_out} (#{format('%.1f%%', max_prob * 100)})
        Confidence: #{format('%.1f%%', confidence * 100)}
        Entropy: #{format('%.3f', entropy)} bits
        KL Divergence from Prior: #{format('%.3f', kl_divergence_from_prior)} bits

        Probabilities:
        #{to_a.map { |o, p| "  #{o}: #{format('%.3f', p)} (#{format('%.1f%%', p * 100)})" }.join("\n")}
      SUMMARY
    end

    private

    # Compute posterior using Bayes' theorem
    # P(outcome | data) = P(data | outcome) × P(outcome) / P(data)
    #
    # @return [Hash] Normalized posterior probabilities
    def compute_posterior
      # Compute unnormalized posterior: likelihood × prior
      unnormalized = @prior.outcomes.each_with_object({}) do |outcome, hash|
        likelihood = @likelihoods[outcome] || 0.0
        prior_prob = @prior.probability(outcome)
        hash[outcome] = likelihood * prior_prob
      end

      # Normalize to sum to 1
      total = unnormalized.values.sum

      if total > 0
        unnormalized.transform_values { |v| v / total }
      else
        # All zeros, fall back to prior
        @prior.outcomes.each_with_object({}) do |outcome, hash|
          hash[outcome] = @prior.probability(outcome)
        end
      end
    end
  end
end
