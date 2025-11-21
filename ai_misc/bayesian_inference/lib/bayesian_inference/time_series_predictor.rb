# frozen_string_literal: true

module BayesianInference
  # Main interface for Bayesian time series prediction
  #
  # TimeSeriesPredictor combines Prior, Likelihood, and Posterior to provide
  # a simple API for predicting probability distributions over discrete outcomes
  # given time series features.
  #
  # @example Basic usage
  #   predictor = TimeSeriesPredictor.new(
  #     outcomes: [-2, -1, 0, 1, 2],
  #     bandwidth: 1.0
  #   )
  #
  #   # Train with historical data
  #   predictor.train([1.0, 2.0, 3.0], outcome: 1)
  #   predictor.train([1.1, 2.1, 2.9], outcome: 1)
  #   predictor.train([-1.0, -2.0, 0.5], outcome: -2)
  #
  #   # Predict for new data
  #   posterior = predictor.predict([1.05, 2.05, 3.0])
  #   puts posterior.summary
  class TimeSeriesPredictor
    attr_reader :outcomes, :prior, :likelihood, :feature_dimension, :bandwidth

    # Initialize predictor
    #
    # @param outcomes [Array] Discrete outcome values (e.g., [-2, -1, 0, 1, 2])
    # @param bandwidth [Float] Kernel bandwidth for likelihood estimation
    # @param prior_probabilities [Hash, nil] Custom prior probabilities
    #   If nil, uses uniform prior
    # @param update_prior [Boolean] Whether to update prior from observations
    #
    # @example
    #   predictor = TimeSeriesPredictor.new(
    #     outcomes: [-2, -1, 0, 1, 2],
    #     bandwidth: 1.0,
    #     update_prior: true
    #   )
    def initialize(outcomes:, bandwidth: 1.0, prior_probabilities: nil, update_prior: true)
      @outcomes = outcomes.sort
      @bandwidth = bandwidth
      @update_prior = update_prior
      @feature_dimension = nil

      # Initialize prior
      @prior = Prior.new(@outcomes, prior_probabilities)

      # Initialize likelihood
      @likelihood = Likelihood.new([], bandwidth: @bandwidth)

      debug_me("Initialized TimeSeriesPredictor") { %i[@outcomes @bandwidth @update_prior] }
    end

    # Train predictor with new observation
    #
    # @param features [Array<Numeric>] Feature vector (e.g., [x, y, z])
    # @param outcome [Numeric] Observed outcome
    # @return [self] For method chaining
    #
    # @example
    #   predictor.train([1.0, 2.0, 3.0], outcome: 1)
    #   predictor.train([1.1, 2.1, 2.9], outcome: 1)
    def train(features, outcome:)
      validate_features!(features)
      validate_outcome!(outcome)

      @likelihood.add_observation(features, outcome)

      # Update prior based on observed frequencies
      if @update_prior && @likelihood.size >= @outcomes.size
        @prior = @prior.update_from_observations(@likelihood.outcome_counts)
      end

      debug_me("Trained with observation") { %i[features outcome @likelihood.size] }

      self
    end

    # Batch train with multiple observations
    #
    # @param observations [Array<Hash>] Array of {features: [...], outcome: ...}
    # @return [self] For method chaining
    #
    # @example
    #   observations = [
    #     {features: [1.0, 2.0, 3.0], outcome: 1},
    #     {features: [1.1, 2.1, 2.9], outcome: 1},
    #     {features: [-1.0, -2.0, 0.5], outcome: -2}
    #   ]
    #   predictor.train_batch(observations)
    def train_batch(observations)
      observations.each do |obs|
        train(obs[:features], outcome: obs[:outcome])
      end
      self
    end

    # Predict posterior distribution for given features
    #
    # @param features [Array<Numeric>] Feature vector to predict
    # @return [Posterior] Posterior probability distribution
    #
    # @example
    #   posterior = predictor.predict([1.0, 2.0, 3.0])
    #   puts "Most likely outcome: #{posterior.max_outcome}"
    #   puts "Confidence: #{posterior.confidence}"
    def predict(features)
      validate_features!(features)

      # Compute likelihoods for all outcomes
      likelihoods = @likelihood.compute(features, @outcomes)

      # Compute posterior
      posterior = Posterior.new(@prior, likelihoods)

      debug_me("Prediction") { [:features, :likelihoods, 'posterior.to_h'] }

      posterior
    end

    # Predict and return most likely outcome
    #
    # @param features [Array<Numeric>] Feature vector
    # @return [Numeric] Most likely outcome (MAP estimate)
    def predict_outcome(features)
      predict(features).max_outcome
    end

    # Predict probabilities as simple hash
    #
    # @param features [Array<Numeric>] Feature vector
    # @return [Hash] {outcome => probability}
    def predict_proba(features)
      predict(features).to_h
    end

    # Get current number of training observations
    #
    # @return [Integer]
    def training_size
      @likelihood.size
    end

    # Check if predictor has been trained
    #
    # @return [Boolean]
    def trained?
      !@likelihood.empty?
    end

    # Get distribution of outcomes in training data
    #
    # @return [Hash] {outcome => count}
    def training_distribution
      @likelihood.outcome_counts
    end

    # Reset predictor to initial state
    #
    # @param keep_prior [Boolean] Whether to keep the current prior
    # @return [self]
    def reset!(keep_prior: false)
      @prior = Prior.new(@outcomes) unless keep_prior
      @likelihood = Likelihood.new([], bandwidth: @bandwidth)
      @feature_dimension = nil
      debug_me "Predictor reset"
      self
    end

    # Update kernel bandwidth for likelihood estimation
    #
    # @param new_bandwidth [Float] New bandwidth value
    # @return [self]
    def bandwidth=(new_bandwidth)
      @bandwidth = new_bandwidth
      # Recreate likelihood with new bandwidth
      @likelihood = Likelihood.new(@likelihood.observations, bandwidth: @bandwidth)
      debug_me("Updated bandwidth") { '@bandwidth' }
      self
    end

    # Get summary statistics
    #
    # @return [String] Formatted summary
    def summary
      <<~SUMMARY
        TimeSeriesPredictor Summary:
        =============================
        Outcomes: #{@outcomes.inspect}
        Feature Dimension: #{@feature_dimension || 'not set'}
        Training Samples: #{training_size}
        Bandwidth: #{@bandwidth}
        Update Prior: #{@update_prior}

        Prior Distribution:
        #{@prior.to_s}
        Prior Entropy: #{format('%.3f', @prior.entropy)} bits

        Training Distribution:
        #{training_distribution.map { |o, c| "  #{o}: #{c}" }.join("\n")}
      SUMMARY
    end

    private

    def validate_features!(features)
      unless features.is_a?(Array) && features.all? { |f| f.is_a?(Numeric) }
        raise ArgumentError, "Features must be array of numbers"
      end

      if @feature_dimension.nil?
        @feature_dimension = features.size
      elsif features.size != @feature_dimension
        raise ArgumentError, "Feature dimension mismatch: expected #{@feature_dimension}, got #{features.size}"
      end
    end

    def validate_outcome!(outcome)
      unless @outcomes.include?(outcome)
        raise ArgumentError, "Invalid outcome: #{outcome}. Must be one of #{@outcomes}"
      end
    end
  end
end
