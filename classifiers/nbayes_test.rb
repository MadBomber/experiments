#!/usr/bin/env ruby
###################################################
###
##  File: nbayes_test.rb
##  Desc: simple classifier
#
# nbayes may be a candidate for crystalruby


require 'amazing_print'
require 'date'

require 'nbayes'

# create new classifier instance

nbayes = NBayes::Base.new

# train it - notice split method used to tokenize text (more on that below)

training_set = Array.new

training_set << ['SPAM', 'You need to buy some Viagra']
training_set << ['HAM',  'This is not spam, just a letter to Bob.']
training_set << ['HAM',  'Hey Oasic, Do you offer consulting?']
training_set << ['SPAM', 'You should buy this stock']
training_set << ['HAM',  'Confirm your appoint with the doctor']
training_set << ['HAM',  'Do not forget to stop at the store for milk and bread']
training_set << ['SPAM', 'Pick up Viagra and Alicia cheaply']


puts "Training ..."
training_set.each do |ts|
  print "#{ts.first}\t"
  puts ts.last
  nbayes.train( ts.last.split(/\s+/), ts.first )
end

puts


# You can save your trained model using the #dump(yml_file),
# and load using the from(yml_file)


puts "Testing ..."

# tokenize message
message = "Now is the time to buy Viagra cheaply and discreetly"
tokens = message.split(/\s+/)
result = nbayes.classify(tokens)

puts
puts "The test message is:"
puts message
puts

print 'likely class (SPAM or HAM): '
p result.max_class

print 'probability of message being SPAM: '
p result['SPAM']

print 'probability of message being HAM: '
p result['HAM']

puts
