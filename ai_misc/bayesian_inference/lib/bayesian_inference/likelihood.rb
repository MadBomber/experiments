# frozen_string_literal: true

module BayesianInference
  # Computes likelihood P(data | outcome) for Bayesian inference
  #
  # The Likelihood class estimates how probable our observed data is
  # given each possible outcome. For time series data with features (x, y, z),
  # it uses kernel density estimation with historical observations.
  class Likelihood
    attr_reader :observations, :bandwidth

    # Initialize likelihood estimator
    #
    # @param observations [Array<Hash>] Historical observations
    #   Each observation: {features: [x, y, z], outcome: result}
    # @param bandwidth [Float] Kernel bandwidth for density estimation
    #   Smaller = more sensitive to local patterns, Larger = smoother estimates
    #
    # @example
    #   observations = [
    #     {features: [1.0, 2.0, 3.0], outcome: 1},
    #     {features: [1.1, 2.1, 2.9], outcome: 1},
    #     {features: [-1.0, -2.0, 0.5], outcome: -2}
    #   ]
    #   likelihood = Likelihood.new(observations, bandwidth: 1.0)
    def initialize(observations = [], bandwidth: 1.0)
      @observations = observations
      @bandwidth = bandwidth
      @outcome_groups = group_by_outcome
      debug_me('Initialized Likelihood') { ['@observations.size', :@bandwidth, '@outcome_groups.keys'] }
    end


    # Add new observation to the likelihood model
    #
    # @param features [Array<Numeric>] Feature vector (e.g., [x, y, z])
    # @param outcome [Numeric] Observed outcome
    # @return [void]
    def add_observation(features, outcome)
      @observations << { features: features, outcome: outcome }
      @outcome_groups = group_by_outcome
      debug_me('Added observation') { [features, outcome, @observations.size] }
    end


    # Compute likelihood P(features | outcome) for each outcome
    #
    # Uses Gaussian kernel density estimation:
    # For each outcome, compute average similarity to historical observations
    # with that outcome using Gaussian kernel.
    #
    # @param features [Array<Numeric>] Query feature vector
    # @param outcomes [Array] All possible outcomes
    # @return [Hash] {outcome => likelihood_value}
    #
    # @example
    #   likelihoods = likelihood.compute([1.0, 2.0, 3.0], [-2, -1, 0, 1, 2])
    #   # => {-2 => 0.05, -1 => 0.1, 0 => 0.15, 1 => 0.6, 2 => 0.1}
    def compute(features, outcomes)
      if @observations.empty?
        # No data yet, return uniform likelihoods
        uniform = 1.0 / outcomes.size
        return outcomes.each_with_object({}) { |o, h| h[o] = uniform }
      end

      likelihoods = outcomes.each_with_object({}) do |outcome, hash|
        hash[outcome] = estimate_density(features, outcome)
      end

      # Normalize likelihoods to sum to 1
      normalize_hash(likelihoods)
    end


    # Estimate kernel density for given features and outcome
    #
    # @param features [Array<Numeric>] Query features
    # @param outcome [Numeric] Target outcome
    # @return [Float] Density estimate
    def estimate_density(features, outcome)
      outcome_obs = @outcome_groups[outcome] || []

      if outcome_obs.empty?
        # No observations for this outcome, return small epsilon
        return 1e-10
      end

      # Gaussian kernel density estimation
      # K(u) = (1 / sqrt(2π)) * exp(-u² / 2)
      # KDE(x) = (1 / n*h) * Σ K((x - xᵢ) / h)

      total_density = outcome_obs.reduce(0.0) do |sum, obs|
        distance = euclidean_distance(features, obs[:features])
        kernel_value = gaussian_kernel(distance / @bandwidth)
        sum + kernel_value
      end

      # Average density
      density = total_density / outcome_obs.size

      # Ensure minimum density to avoid zero probabilities
      [density, 1e-10].max
    end


    # Get number of observations
    #
    # @return [Integer]
    def size
      @observations.size
    end


    # Check if likelihood model is empty
    #
    # @return [Boolean]
    def empty?
      @observations.empty?
    end


    # Get count of observations for each outcome
    #
    # @return [Hash] {outcome => count}
    def outcome_counts
      @outcome_groups.transform_values(&:size)
    end

    private

    # Group observations by outcome
    #
    # @return [Hash] {outcome => [observations]}
    def group_by_outcome
      @observations.group_by { |obs| obs[:outcome] }
    end


    # Compute Euclidean distance between two feature vectors
    #
    # @param v1 [Array<Numeric>] First vector
    # @param v2 [Array<Numeric>] Second vector
    # @return [Float] Euclidean distance
    def euclidean_distance(v1, v2)
      raise ArgumentError, 'Feature vectors must have same dimension' unless v1.size == v2.size

      Math.sqrt(v1.zip(v2).reduce(0.0) { |sum, (a, b)| sum + (a - b)**2 })
    end


    # Gaussian kernel function
    #
    # @param u [Float] Normalized distance
    # @return [Float] Kernel value
    def gaussian_kernel(u)
      (1.0 / Math.sqrt(2 * Math::PI)) * Math.exp(-0.5 * u**2)
    end


    # Normalize hash values to sum to 1
    #
    # @param hash [Hash] Hash with numeric values
    # @return [Hash] Normalized hash
    def normalize_hash(hash)
      total = hash.values.sum

      if total > 0
        hash.transform_values { |v| v / total }
      else
        # All zeros, return uniform
        uniform = 1.0 / hash.size
        hash.transform_values { uniform }
      end
    end
  end
end
