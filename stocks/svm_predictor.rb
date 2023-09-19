#!/usr/bin/env ruby
# experiments/stocks/svm_predictor.rb

require 'libsvm'

# Define the features and labels array for training the SVM model
features  = []
labels    = []

# Training data set
training_data = [
  {adjusted_close_price: 10.0, high_price: 12.0, low_price:  9.0, volume: 100, swing: 'up'},
  {adjusted_close_price:  9.5, high_price: 11.5, low_price:  8.5, volume: 150, swing: 'down'},
  {adjusted_close_price: 11.0, high_price: 13.0, low_price: 10.0, volume: 200, swing: 'up'},
  # Add more training data here
]

# Populate features and labels arrays from training data
training_data.each do |data|
  features  << [data[:adjusted_close_price], data[:high_price], data[:low_price], data[:volume]]
  labels    << (data[:swing] == 'up' ? 1 : -1)
end

# Train the SVM model using LIBSVM gem
problem   = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size  = 1
parameter.eps         = 0.001
parameter.c           = 10

problem.set_examples(labels, features)

model = Libsvm::Model.train(problem, parameter)

# Method to predict stock swing
def predict_stock_swing(stock_data)
  current_data = [
    stock_data[:adjusted_close_price],
    stock_data[:high_price],
    stock_data[:low_price],
    stock_data[:volume]
  ]

  prediction = model.predict(Libsvm::Node.features(current_data))
  prediction == 1 ? 'up' : 'down'
end

# Usage
stock_data = {adjusted_close_price: 12.5, high_price: 14.0, low_price: 11.0, volume: 120}
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
