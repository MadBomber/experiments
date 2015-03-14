#!/usr/bin/env ruby -wKU
require 'words'

#data = Words::Wordnet.new # or: data = Words::Wordnet.new(:tokyo) for the tokyo backend

# to specify a wordnet path Words::Words.new(:pure, '/path/to/wordnet')
# to specify the tokyo dataset Words::Words.new(:pure, :search, '/path/to/data.tct')

# Need to yum install wordnet wordnet-*
data = Words::Wordnet.new(:pure, '/usr/share/wordnet-3.0/dict')



# play with connections
data.connected? # => true
data.close!
data.connected? # => false
data.open!
data.connected? # => true
data.connection_type # => :pure or :tokyo depending...

# locate a word
lemma = data.find("bat")

lemma.to_s # => bat, noun/verb
lemma.available_pos.inspect # => [:noun, :verb]

lemma.synsets(:noun) # => array of synsets which represent nouns of the lemma bat
# or
lemma.nouns # => array of synsets which represent nouns of the lemma bat
lemma.noun_ids # => array of synsets ids which represent nouns of the lemma bat
lemma.verbs? #=> true

# specify a sense
sense = lemma.nouns.last
sense2 = lemma.nouns[2]

sense.gloss # => a club used for hitting a ball in various games
sense2.words # => ["cricket bat", "bat"]
sense2.lexical_description # => a description of the lexical meaning of the synset
sense.relations.first # => "Semantic hypernym relation between n02806379 and n03053474"

sense.relations(:hyponym) # => Array of hyponyms associated with the sense
# or
sense.hyponyms # => Array of hyponyms associated with the sense
sense.hyponyms? # => true

sense.relations.first.is_semantic? # => true
sense.relations.first.source_word # => nil
sense.relations.first.destination # => the synset of n03053474

sense.derivationally_related_forms.first.is_semantic? # => false
sense.derivationally_related_forms.first.source_word # => "bat"
sense.derivationally_related_forms.first.destination_word # => "bat"
sense.derivationally_related_forms.first.destination # => the synset of v01413191

if data.evocations? # check for evocation support
   data.find("broadcast").senses.first.evocations # => sense relevant evocations
   data.find("broadcast").senses.first.evocations[1] # => the evocation at index 1
   data.find("broadcast").senses.first.evocations[1][:destination].words # => synset
end

data.close!
