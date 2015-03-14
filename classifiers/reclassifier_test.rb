#!/usr/bin/env ruby
###################################################
###
##  File: reclassifier_test.rb
##  Desc: simple classifier (bayes and LSI)
#

require 'assertions'
include Assertions

require 'awesome_print'
require 'date'


require "gsl"
require 'reclassifier'    # FIXME: needs require 'set'; also need gsl for lsi

b = Reclassifier::Bayes.new( [ :interesting, :uninteresting ] )
b.train( :interesting, "here are some good words. I hope you love them")
b.train( :uninteresting, "here are some bad words, I hate you")

assert_equal :uninteresting, b.classify("I hate bad words and you")


require 'madeleine'
require 'madeleine/zmarshal'

m = SnapshotMadeleine.new("bayes_data") {
    Reclassifier::Bayes.new( [ :interesting, :uninteresting ] )
}
m.system.train( :interesting, "here are some good words. I hope you love them")
m.system.train( :uninteresting, "here are some bad words, I hate you")
m.take_snapshot

assert_equal :interesting, m.system.classify("I love you")




lsi = Reclassifier::LSI.new

strings = [ ["This text deals with dogs. Dogs.", :dog],
            ["This text involves dogs too. Dogs! ", :dog],
            ["This text revolves around cats. Cats.", :cat],
            ["This text also involves cats. Cats!", :cat],
            ["This text involves birds. Birds.",:bird ]]

strings.each {|x| lsi.add_item x.first, x.last}

puts lsi.search("dog", 3)
# returns => ["This text deals with dogs. Dogs.", "This text involves dogs too. Dogs! ",
#             "This text also involves cats. Cats!"]

puts lsi.find_related(strings[2], 2)
# returns => ["This text revolves around cats. Cats.", "This text also involves cats. Cats!"]

assert_equal :dog, lsi.classify("This text is also about dogs!")

