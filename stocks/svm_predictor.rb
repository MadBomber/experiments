#!/usr/bin/env ruby
# experiments/stocks/svm_predictor.rb

require 'libsvm'

# Define the features and labels array for training the SVM model
samples   = []
labels    = []

# Training data set
training_data = [
  # U/D,  acp, high,  low, vol],
  [-1.0, 10.0, 12.0,  9.0, 100],
  [ 1.0,  9.5, 11.5,  8.5, 150],
  [-1.0, 11.0, 13.0, 10.0, 200],
  # Add more training data here
]

# Populate features and labels arrays from training data
training_data.each do |data|
  samples   << data
  labels    << data[0]
end

# Train the SVM model using LIBSVM gem
problem   = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size  = 1
parameter.eps         = 0.001
parameter.c           = 10

examples = samples.map {|ary| Libsvm::Node.features(ary) }


problem.set_examples(labels, examples)

model = Libsvm::Model.train(problem, parameter)

# Method to predict stock swing
def predict_stock_swing(stock_data)
  current_data  = stock_data
  prediction    = model.predict(Libsvm::Node.features(current_data))
  prediction.positive? ? 'up' : 'down'
end

# Usage
#              ajc   high  low   vol
stock_data = [ 12.5, 14.0, 11.0, 120]
prediction = predict_stock_swing(stock_data)

puts "The stock is predicted to swing #{prediction}."


__END__

The method `predict_stock_swing` takes an array of stock market data
and predicts if the specific stock will swing up or down based on the
features provided (adjusted close price, high price, low price, and
  volume data) for the previous days. It uses the LIBSVM gem to train
an SVM model with the provided training data and then predicts the stock
swing using the trained model.

To use the method, you can provide the current stock data as a hash with
the required attributes (`adjusted_close_price`, `high_price`, `low_price`,
and `volume`). The method will return the predicted swing as a string ('up'
or 'down').
