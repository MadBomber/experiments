# frozen_string_literal: true

require_relative 'bayesian_inference/version'
require_relative 'bayesian_inference/prior'
require_relative 'bayesian_inference/likelihood'
require_relative 'bayesian_inference/posterior'
require_relative 'bayesian_inference/time_series_predictor'

# Bayesian Inference for Time Series Prediction
#
# This module provides a framework for Bayesian inference on discrete outcomes
# from time series data. It implements:
#
# - Prior distributions with Laplace smoothing
# - Kernel density estimation for likelihoods
# - Bayesian posterior computation
# - Time series prediction with probability distributions
#
# @example Basic usage
#   include BayesianInference
#
#   predictor = TimeSeriesPredictor.new(
#     outcomes: [-2, -1, 0, 1, 2],
#     bandwidth: 1.0
#   )
#
#   # Train with data
#   predictor.train([1.0, 2.0, 3.0], outcome: 1)
#   predictor.train([1.1, 2.1, 2.9], outcome: 1)
#
#   # Predict
#   posterior = predictor.predict([1.05, 2.05, 3.0])
#   puts posterior.summary
module BayesianInference
  class Error < StandardError; end

  # Convenience method to create a predictor
  #
  # @param outcomes [Array] Discrete outcomes
  # @param bandwidth [Float] Kernel bandwidth
  # @return [TimeSeriesPredictor]
  def self.predictor(outcomes:, bandwidth: 1.0, **options)
    TimeSeriesPredictor.new(outcomes: outcomes, bandwidth: bandwidth, **options)
  end
end
