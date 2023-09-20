#!/usr/bin/env ruby
# experiments/libsvm/rumale_svm/rumale_svm_test.rb
#

# Evaluate classifiction accuracy on testing datase.

require 'rumale/svm'
require 'rumale/dataset'

samples, labels = Rumale::Dataset.load_libsvm_file('pendigits.t')
svc 						= Marshal.load(File.binread('svc.dat'))

puts "Accuracy: #{svc.score(samples, labels).round(3)}"

# Execution result.

# $ ruby rumale_svm_train.rb
# $ ls svc.dat
# svc.dat
# $ ruby rumale_svm_test.rb
# Accuracy: 0.835
