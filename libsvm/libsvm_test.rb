#!/usr/bin/env ruby

require 'libsvm'

# This library is namespaced.
problem 	= Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size 	= 1 # in megabytes
parameter.eps 				= 0.001
parameter.c 					= 10

samples = [
	[ 1, 0, 1],
	[-1, 0, -1]
]

examples = samples.map {|ary| Libsvm::Node.features(ary) }

labels = [1, -1]

problem.set_examples(labels, examples)

model = Libsvm::Model.train(problem, parameter)

pred = model.predict(Libsvm::Node.features(1, 1, 1))
puts "Example [1, 1, 1] - Predicted #{pred}"
