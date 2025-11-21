# frozen_string_literal: true

module BayesianInference
  # Manages prior probability distributions over discrete outcomes
  #
  # The Prior class represents our initial beliefs about outcome probabilities
  # before observing any data. It supports:
  # - Uniform priors (equal probability for all outcomes)
  # - Custom priors (specified probabilities)
  # - Dynamic updating based on historical observations
  class Prior
    attr_reader :outcomes, :probabilities

    # Initialize a prior distribution
    #
    # @param outcomes [Array] Discrete outcomes (e.g., [-2, -1, 0, 1, 2])
    # @param probabilities [Hash, nil] Optional custom probabilities {outcome => probability}
    #   If nil, uses uniform distribution
    #
    # @example Uniform prior
    #   prior = Prior.new([-2, -1, 0, 1, 2])
    #
    # @example Custom prior favoring neutral outcome
    #   prior = Prior.new([-2, -1, 0, 1, 2], {-2 => 0.1, -1 => 0.15, 0 => 0.5, 1 => 0.15, 2 => 0.1})
    def initialize(outcomes, probabilities = nil)
      @outcomes = outcomes.sort

      if probabilities
        validate_probabilities!(probabilities)
        @probabilities = probabilities
      else
        # Uniform prior: equal probability for all outcomes
        uniform_prob = 1.0 / outcomes.size
        @probabilities = outcomes.each_with_object({}) do |outcome, hash|
          hash[outcome] = uniform_prob
        end
      end

      debug_me("Initialized Prior") { %i[@outcomes @probabilities] }
    end

    # Get probability for a specific outcome
    #
    # @param outcome [Numeric] The outcome to query
    # @return [Float] Probability of the outcome
    def probability(outcome)
      @probabilities[outcome] || 0.0
    end
    alias_method :[], :probability

    # Update prior based on observed outcome frequencies
    #
    # Uses Laplace smoothing (add-1 smoothing) to avoid zero probabilities
    #
    # @param observations [Hash] Observed outcome frequencies {outcome => count}
    # @param smoothing [Float] Laplace smoothing parameter (default: 1.0)
    # @return [Prior] New Prior instance with updated probabilities
    #
    # @example
    #   observations = {-2 => 5, -1 => 10, 0 => 20, 1 => 12, 2 => 3}
    #   updated_prior = prior.update_from_observations(observations)
    def update_from_observations(observations, smoothing: 1.0)
      total_count = observations.values.sum

      new_probabilities = @outcomes.each_with_object({}) do |outcome, hash|
        # Laplace smoothing: (count + smoothing) / (total + smoothing * num_outcomes)
        count = observations[outcome] || 0
        hash[outcome] = (count + smoothing) / (total_count + smoothing * @outcomes.size)
      end

      debug_me("Updated Prior from observations") { %i[observations new_probabilities] }

      self.class.new(@outcomes, new_probabilities)
    end

    # Combine this prior with another using weighted average
    #
    # @param other_prior [Prior] Another prior distribution
    # @param weight [Float] Weight for this prior (0.0 to 1.0)
    # @return [Prior] New Prior with combined probabilities
    def combine(other_prior, weight: 0.5)
      unless outcomes_compatible?(other_prior)
        raise ArgumentError, "Cannot combine priors with different outcomes"
      end

      new_probabilities = @outcomes.each_with_object({}) do |outcome, hash|
        hash[outcome] = weight * probability(outcome) +
                       (1 - weight) * other_prior.probability(outcome)
      end

      self.class.new(@outcomes, new_probabilities)
    end

    # Get entropy of the prior distribution
    # Higher entropy = more uncertain/uniform, Lower entropy = more peaked/certain
    #
    # @return [Float] Shannon entropy in bits
    def entropy
      -@probabilities.values.reduce(0.0) do |sum, prob|
        sum + (prob > 0 ? prob * Math.log2(prob) : 0)
      end
    end

    # Return a human-readable representation
    #
    # @return [String] Formatted probability distribution
    def to_s
      parts = @outcomes.map { |o| "#{o}: #{format('%.3f', probability(o))}" }
      "Prior(#{parts.join(', ')})"
    end

    private

    def validate_probabilities!(probabilities)
      # Check all outcomes are present
      missing = @outcomes - probabilities.keys
      unless missing.empty?
        raise ArgumentError, "Missing probabilities for outcomes: #{missing}"
      end

      # Check probabilities sum to 1.0 (with small tolerance)
      total = probabilities.values.sum
      unless (total - 1.0).abs < 1e-6
        raise ArgumentError, "Probabilities must sum to 1.0, got #{total}"
      end

      # Check all probabilities are non-negative
      negative = probabilities.select { |_k, v| v < 0 }
      unless negative.empty?
        raise ArgumentError, "Probabilities must be non-negative: #{negative}"
      end
    end

    def outcomes_compatible?(other_prior)
      @outcomes == other_prior.outcomes
    end
  end
end
