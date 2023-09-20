#!/usr/bin/env ruby
# experiments/libsvm/rumale_svm/rumale_svm_train.rb
#
# Get datasets ...
#
# wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/multiclass/pendigits
# wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/multiclass/pendigits.t

# Training linear support vector classifier.

require 'rumale/svm'
require 'rumale/dataset'

require 'debug_me'
include DebugMe


samples, labels = Rumale::Dataset.load_libsvm_file('pendigits')
svc 						= Rumale::SVM::LinearSVC.new(random_seed: 1)

debug_me{[
	"samples.size",
	:labels
]}

svc.fit(samples, labels)

File.open('svc.dat', 'wb') { |f| f.write(Marshal.dump(svc)) }
