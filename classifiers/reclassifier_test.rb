#!/usr/bin/env ruby
###################################################
###
##  File: reclassifier_test.rb
##  Desc: simple classifier (bayes and LSI)
#

require 'awesome_print'
require 'date'

require 'reclassifier'    # FIXME: needs require 'set'

b = Reclassifier::Bayes.new( [ :interesting, :uninteresting ] )
b.train( :interesting, "here are some good words. I hope you love them")
b.train( :uninteresting, "here are some bad words, I hate you")
b.classify "I hate bad words and you" # returns ':uninteresting'


puts "Madeleine does not work"

=begin

rescue Exception => e

end
require 'madeleine'
require 'madeleine/zmarshal'

m = SnapshotMadeleine.new("bayes_data") {
    Reclassifier::Bayes.new( [ :interesting, :uninteresting ] )
}
m.system.train( :interesting, "here are some good words. I hope you love them")
m.system.train( :uninteresting, "here are some bad words, I hate you")
m.take_snapshot
m.system.classify "I love you" # returns 'Interesting'

=end

puts "LSI does not work"

=begin

rescue Exception => e

end
lsi = Reclassifier::LSI.new
strings = [ ["This text deals with dogs. Dogs.", :dog],
            ["This text involves dogs too. Dogs! ", :dog],
            ["This text revolves around cats. Cats.", :cat],
            ["This text also involves cats. Cats!", :cat],
            ["This text involves birds. Birds.",:bird ]]
strings.each {|x| lsi.add_item x.first, x.last}

lsi.search("dog", 3)
# returns => ["This text deals with dogs. Dogs.", "This text involves dogs too. Dogs! ",
#             "This text also involves cats. Cats!"]

lsi.find_related(strings[2], 2)
# returns => ["This text revolves around cats. Cats.", "This text also involves cats. Cats!"]

lsi.classify "This text is also about dogs!"
# returns => :dog

=end
