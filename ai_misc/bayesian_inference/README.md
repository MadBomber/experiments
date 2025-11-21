# Bayesian Inference for Time Series Prediction

A Ruby framework for Bayesian inference on discrete outcomes from time series data. Predicts probability distributions over discrete outcomes given historical observations and current features.

## Overview

This library implements Bayesian inference for time series classification problems where:
- **Input**: Time series features (e.g., x, y, z values)
- **Output**: Probability distribution over discrete outcomes (e.g., {-2, -1, 0, 1, 2})
- **Method**: Combines prior beliefs with likelihood estimation via Bayes' theorem

### Key Features

- **Prior Distributions**: Uniform or custom priors with automatic updating from observations
- **Kernel Density Estimation**: Gaussian kernels for likelihood computation from historical data
- **Posterior Inference**: Full Bayesian updates using Bayes' theorem
- **Uncertainty Quantification**: Entropy, confidence scores, and sampling from posteriors
- **Time Series Support**: Handles multi-dimensional feature vectors with temporal context

## Installation

Add to your Gemfile:

```ruby
gem 'debug_me', '~> 1.1'
gem 'minitest', '~> 5.0'
gem 'matrix', '~> 0.4'
```

Then run:

```bash
bundle install
```

## Quick Start

```ruby
require_relative 'lib/bayesian_inference'

# Create predictor for 5 discrete outcomes
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 1.0
)

# Train with historical observations
predictor.train([1.0, 2.0, 3.0], outcome: 1)
predictor.train([1.1, 2.1, 2.9], outcome: 1)
predictor.train([-1.0, -2.0, 0.5], outcome: -2)

# Predict probability distribution for new data
posterior = predictor.predict([1.05, 2.05, 3.0])

puts "Most likely outcome: #{posterior.max_outcome}"
puts "Confidence: #{posterior.confidence}"
puts posterior.summary
```

## Architecture

### Components

```
BayesianInference/
├── Prior           # P(outcome) - Prior probability distribution
├── Likelihood      # P(data|outcome) - Kernel density estimation
├── Posterior       # P(outcome|data) - Bayesian posterior via Bayes' theorem
└── TimeSeriesPredictor  # Main API combining all components
```

### Mathematical Foundation

**Bayes' Theorem:**
```
P(outcome | data) = P(data | outcome) × P(outcome) / P(data)

Posterior = Likelihood × Prior / Evidence
```

**Kernel Density Estimation (for Likelihood):**
```
P(x | outcome) = (1/n) × Σ K((x - xᵢ) / h)

where:
  K = Gaussian kernel
  h = bandwidth parameter
  xᵢ = historical observations with given outcome
```

## Usage

### Basic Prediction

```ruby
# Initialize predictor
predictor = BayesianInference::TimeSeriesPredictor.new(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 0.8,        # Kernel bandwidth
  update_prior: true     # Learn prior from observations
)

# Train with data
observations = [
  {features: [1.0, 2.0, 3.0], outcome: 1},
  {features: [1.1, 2.1, 2.9], outcome: 1},
  {features: [-1.0, -2.0, 0.5], outcome: -2}
]
predictor.train_batch(observations)

# Make predictions
posterior = predictor.predict([1.0, 2.0, 3.0])

# Access results
posterior.max_outcome           # Most likely outcome (MAP estimate)
posterior.probability(1)        # P(outcome=1 | data)
posterior.confidence            # Confidence score (0-1)
posterior.entropy               # Shannon entropy
posterior.top_outcomes(3)       # Top 3 outcomes with probabilities
```

### Working with Priors

```ruby
# Uniform prior (default)
prior = BayesianInference::Prior.new([-2, -1, 0, 1, 2])

# Custom prior
prior = BayesianInference::Prior.new(
  [-2, -1, 0, 1, 2],
  {-2 => 0.1, -1 => 0.2, 0 => 0.4, 1 => 0.2, 2 => 0.1}
)

# Update prior from observations
observations = {-2 => 5, -1 => 10, 0 => 30, 1 => 10, 2 => 5}
updated_prior = prior.update_from_observations(observations)

# Combine priors
combined = prior1.combine(prior2, weight: 0.7)

# Check entropy
prior.entropy  # Higher = more uncertain
```

### Likelihood Estimation

```ruby
# Create likelihood model
likelihood = BayesianInference::Likelihood.new([], bandwidth: 1.0)

# Add observations
likelihood.add_observation([1.0, 2.0, 3.0], 1)
likelihood.add_observation([1.1, 2.1, 2.9], 1)

# Compute likelihoods for all outcomes
likelihoods = likelihood.compute([1.0, 2.0, 3.0], [-2, -1, 0, 1, 2])
# => {-2 => 0.05, -1 => 0.1, 0 => 0.15, 1 => 0.6, 2 => 0.1}
```

### Posterior Analysis

```ruby
posterior = predictor.predict([1.0, 2.0, 3.0])

# Point estimates
posterior.max_outcome              # MAP estimate
posterior.predict_outcome([...])   # Convenience method

# Uncertainty quantification
posterior.entropy                  # Shannon entropy
posterior.confidence               # Normalized confidence (0-1)
posterior.kl_divergence_from_prior # Information gain

# Sampling (Monte Carlo)
samples = posterior.samples(1000)
sample_mean = samples.sum / samples.size

# Distribution analysis
posterior.to_h                     # {outcome => probability}
posterior.to_a                     # [[outcome, prob], ...] sorted
posterior.top_outcomes(n)          # Top N outcomes
```

## Examples

### Example 1: Coin Flip Bias Estimation

See `examples/coin_flip.rb` for a complete example of estimating coin bias from flip sequences.

```bash
ruby examples/coin_flip.rb
```

**Problem**: Given a sequence of coin flips, estimate the bias level:
- -2: Very biased toward tails
- -1: Slightly biased toward tails
- 0: Fair coin
- 1: Slightly biased toward heads
- 2: Very biased toward heads

### Example 2: Time Series Prediction (Main Use Case)

See `examples/time_series_prediction.rb` for the complete example matching your use case.

```bash
ruby examples/time_series_prediction.rb
```

**Problem**: Given three time series variables (x, y, z), predict market trend:
- x: Price momentum
- y: Volume indicator
- z: Volatility measure
- Outcomes: {-2, -1, 0, 1, 2} representing trend strength

## Testing

Run tests with:

```bash
cd bayesian_inference
bundle install
ruby test/bayesian_inference_test.rb
```

Or with rake:

```bash
rake test
```

## Configuration

### Bandwidth Selection

The `bandwidth` parameter controls the smoothness of likelihood estimation:

- **Small bandwidth** (e.g., 0.3): More sensitive to local patterns, higher variance
- **Medium bandwidth** (e.g., 1.0): Balanced smoothness, good default
- **Large bandwidth** (e.g., 3.0): Smoother estimates, lower variance

```ruby
# Experiment with different bandwidths
[0.5, 1.0, 2.0].each do |bw|
  predictor = BayesianInference.predictor(outcomes: [-2, -1, 0, 1, 2], bandwidth: bw)
  # ... train and evaluate
end
```

### Prior Update Strategy

```ruby
# Fixed uniform prior
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  update_prior: false  # Keep uniform prior
)

# Learned prior from data
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  update_prior: true   # Update from observation frequencies
)

# Custom prior
predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  prior_probabilities: {-2 => 0.1, -1 => 0.2, 0 => 0.4, 1 => 0.2, 2 => 0.1}
)
```

## API Reference

### TimeSeriesPredictor

**Constructor:**
```ruby
TimeSeriesPredictor.new(
  outcomes: Array,              # Discrete outcome values
  bandwidth: Float,             # Kernel bandwidth (default: 1.0)
  prior_probabilities: Hash,    # Custom prior (default: nil = uniform)
  update_prior: Boolean         # Auto-update prior (default: true)
)
```

**Methods:**
- `train(features, outcome:)` - Add single observation
- `train_batch(observations)` - Add multiple observations
- `predict(features)` - Return Posterior distribution
- `predict_outcome(features)` - Return most likely outcome
- `predict_proba(features)` - Return probability hash
- `reset!(keep_prior: false)` - Clear training data
- `bandwidth=(new_bandwidth)` - Update bandwidth
- `training_size` - Number of observations
- `trained?` - Check if any training data exists

### Prior

**Methods:**
- `probability(outcome)` / `[outcome]` - Get P(outcome)
- `update_from_observations(observations, smoothing: 1.0)` - Update from data
- `combine(other_prior, weight: 0.5)` - Weighted combination
- `entropy` - Shannon entropy

### Likelihood

**Methods:**
- `add_observation(features, outcome)` - Add observation
- `compute(features, outcomes)` - Compute likelihoods for all outcomes
- `estimate_density(features, outcome)` - KDE for specific outcome
- `outcome_counts` - Frequency of each outcome

### Posterior

**Methods:**
- `probability(outcome)` / `[outcome]` - Get P(outcome | data)
- `max_outcome` - Most likely outcome (MAP)
- `top_outcomes(n)` - Top N outcomes
- `entropy` - Shannon entropy
- `confidence` - Normalized confidence (0-1)
- `kl_divergence_from_prior` - Information gain
- `sample(rng:)` - Single sample
- `samples(n, rng:)` - Multiple samples
- `to_h` / `to_a` - Distribution as hash/array

## Use Cases

### Financial Markets
- Predict trend direction from momentum, volume, volatility
- Outcomes: strong down, down, neutral, up, strong up

### Manufacturing Quality
- Predict defect severity from sensor readings
- Outcomes: critical, major, minor, acceptable, excellent

### Healthcare Monitoring
- Predict patient condition from vital signs
- Outcomes: critical, concerning, stable, good, excellent

### Weather Forecasting
- Predict weather conditions from atmospheric measurements
- Outcomes: storm, rain, cloudy, partly cloudy, clear

## Performance Considerations

- **Training**: O(n) per observation where n = training set size
- **Prediction**: O(n × k) where k = number of outcomes
- **Memory**: Stores all training observations (consider sampling for large datasets)

For large datasets:
1. Use representative sampling
2. Periodically retrain with recent data
3. Consider batch training for efficiency

## Mathematical Details

### Laplace Smoothing

The prior update uses Laplace (add-1) smoothing to avoid zero probabilities:

```
P(outcome) = (count + α) / (total + α × k)

where:
  α = smoothing parameter (default: 1.0)
  k = number of outcomes
```

### Gaussian Kernel

The likelihood estimation uses a Gaussian kernel:

```
K(u) = (1 / √(2π)) × exp(-u² / 2)

where u = distance / bandwidth
```

### Entropy

Shannon entropy measures uncertainty:

```
H(X) = -Σ P(x) × log₂(P(x))

Range: [0, log₂(k)] where k = number of outcomes
```

## Contributing

This is an experimental framework. To extend:

1. Add new kernel functions in `likelihood.rb`
2. Implement alternative prior update strategies in `prior.rb`
3. Add evaluation metrics in `posterior.rb`
4. Create new examples for different domains

## License

Experimental code for research and learning purposes.

## References

- Bayes' Theorem: [Wikipedia](https://en.wikipedia.org/wiki/Bayes%27_theorem)
- Kernel Density Estimation: [Wikipedia](https://en.wikipedia.org/wiki/Kernel_density_estimation)
- Laplace Smoothing: [Wikipedia](https://en.wikipedia.org/wiki/Additive_smoothing)
- Shannon Entropy: [Wikipedia](https://en.wikipedia.org/wiki/Entropy_(information_theory))
