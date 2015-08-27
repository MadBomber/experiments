#!/usr/bin/env ruby

require 'kick_the_tires'
include KickTheTires

require 'classifier-reborn'

lsi = ClassifierReborn::LSI.new

strings = [ ["This text deals with dogs. Dogs.", :dog],
            ["This text involves dogs too. Dogs! ", :dog],
            ["This text revolves around cats. Cats.", :cat],
            ["This text also involves cats. Cats!", :cat],
            ["This text involves birds. Birds.",:bird ]]

strings.each {|x| lsi.add_item x.first, x.last}

result = lsi.search("dog", 3)
# returns => ["This text deals with dogs. Dogs.", 
#             "This text involves dogs too. Dogs! ",
#             "This text also involves cats. Cats!"]

assert_equal Array, result.class
assert_equal 3, result.size

assert result.include?("This text deals with dogs. Dogs.")
assert result.include?("This text involves dogs too. Dogs! ")
assert result.include?("This text also involves cats. Cats!")

show result


result = lsi.find_related(strings[2], 2)
# returns => ["This text revolves around cats. Cats.", "This text also involves cats. Cats!"]

show result

result = lsi.classify "This text is also about dogs!"
# returns => :dog

assert_equal :dog, result

