#!/usr/bin/env ruby
# encoding: utf-8

require 'kick_the_tires'
include KickTheTires

require 'words'

#     data = Words::Wordnet.new
# or: data = Words::Wordnet.new(:tokyo) for the tokyo backend

# to specify a wordnet path Words::Words.new(:pure, '/path/to/wordnet')
# to specify the tokyo dataset Words::Words.new(:tokyo, :search, '/path/to/data.tct')

# Need to yum install wordnet wordnet-*
# you can use :pure or :tokyo cabinet-based data stores
data = Words::Wordnet.new(:pure, '/usr/share/wordnet-3.0/dict')


# play with connections
assert data.connected?

data.close!

refute data.connected?

data.open!

assert data.connected?

assert_equal :pure, data.connection_type

# locate a word
lemma = data.find("bat")

assert_equal 'bat, noun/verb', lemma.to_s

assert_equal [:noun, :verb], lemma.available_pos.inspect

show lemma.synsets(:noun)   # or lemma.nouns

show lemma.noun_ids

assert lemma.verbs?

# specify a sense
sense  = lemma.nouns.last
sense2 = lemma.nouns[2]

assert_equal 'a club used for hitting a ball in various games',
                sense.gloss

assert_equal ["cricket bat", "bat"], sense2.words

show sense2.lexical_description

assert_equal 'Semantic hypernym relation between n02806379 and n03053474',
                sense.relations.first

show sense.relations(:hyponym)  # or sense.hyponyms

assert sense.hyponyms?

assert sense.relations.first.is_semantic?

assert_equal nil, sense.relations.first.source_word

show sense.relations.first.destination

refute sense.derivationally_related_forms.first.is_semantic?

assert_equal 'bat', sense.derivationally_related_forms.first.source_word

assert_equal 'bat', sense.derivationally_related_forms.first.destination_word

show sense.derivationally_related_forms.first.destination

if data.evocations? # check for evocation support
   # sense relevant evocations
   show data.find("broadcast").senses.first.evocations
   show data.find("broadcast").senses.first.evocations[1]
   show data.find("broadcast").senses.first.evocations[1][:destination].words
end

hands_on

data.close!
