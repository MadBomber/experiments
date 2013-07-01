#!/usr/bin/env ruby
###################################################
###
##  File: nbayes_test.rb
##  Desc: simple classifier
#

require 'awesome_print'
require 'date'

require 'nbayes'

# create new classifier instance

nbayes = NBayes::Base.new

# train it - notice split method used to tokenize text (more on that below)

nbayes.train( "You need to buy some Viagra".split(/\s+/), 'SPAM' )
nbayes.train( "This is not spam, just a letter to Bob.".split(/\s+/), 'HAM' )
nbayes.train( "Hey Oasic, Do you offer consulting?".split(/\s+/), 'HAM' )
nbayes.train( "You should buy this stock".split(/\s+/), 'SPAM' )

# You can save your trained model using the #dump(yml_file),
# and load using the from(yml_file)


# tokenize message
tokens = "Now is the time to buy Viagra cheaply and discreetly".split(/\s+/)
result = nbayes.classify(tokens)

# print likely class (SPAM or HAM)
p result.max_class

# print probability of message being SPAM
p result['SPAM']

# print probability of message being HAM
p result['HAM']
