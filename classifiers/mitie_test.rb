#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: mitie_test.rb
##  Desc: Testing the mitie gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'mitie'
# named-entity recognition, binary relation detection, and text categorization - for Ruby
#
#    Finds people, organizations, and locations in text
#    Detects relationships between entities, like PERSON was born in LOCATION

require 'pathname'

MITIE_MODEL_DIR = "/Volumes/WoFat250/MITIE-models/english/"



require 'amazing_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("Testing the mitie gem") do |o|

  # o.bool    '-b', '--bool',   'example boolean parameter',   default: false
  # o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  # o.int     '-i', '--int',    'example integer parameter',   default: 42
  # o.float   '-f', '--float',  'example float parameter',     default: 123.456
  # o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  # o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  # o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# # Display the usage info
# if  ARGV.empty?
#   show_usage
#   exit
# end


# Error check your stuff; use error('some message') and warning('some message')

# configatron.input_files = get_pathnames_from( configatron.arguments, '.txt')

# if configatron.input_files.empty?
#   error 'No text files were provided'
# end

abort_if_errors


######################################################
# Local methods

def h1(a_string='')
  print "\n\n"
  puts a_string
  puts "="*a_string.size
  puts
end

def h2(a_string='')
  puts
  puts a_string
  puts "-"*a_string.size
  puts
end

def error(expected_object)
  puts "\nERROR: Did not get expected object ..."
  ap expected_object
  print "\n\n"
end

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

h1 "Named Entity Recognition"

h2 "Load an NER model"

model = Mitie::NER.new(MITIE_MODEL_DIR + "ner_model.dat")

h2 "Create a document"

doc = model.doc <<~DOC
  Nat works at GitHub in San Francisco.

  Dewayne applies his talents in Bossier City (which
  is located in LousyAnna) as a remote
  system/software developer for many companies.
DOC

h2 "Get entities"

ap doc.entities

h2 "Get tokens"

ap doc.tokens

h2 "Get tokens and their offset"

ap doc.tokens_with_offset

h2 "Get all tags for a model"

ap model.tags

h1 "Training"

h2 "Load an NER model into a trainer"

trainer = Mitie::NERTrainer.new(MITIE_MODEL_DIR+"total_word_feature_extractor.dat")

h2 "Create training instances"

tokens    = %w[You can do machine learning in Ruby !]
instance  = Mitie::NERTrainingInstance.new(tokens)

ap instance.add_entity(3..4, "topic")    # machine learning
ap instance.add_entity(6..6, "language") # Ruby

h2 "Add the training instances to the trainer"

ap trainer.add(instance)

h2 "Train the model"

model = trainer.train

ap model

h2 "Save the model"

model.save_to_disk(MITIE_MODEL_DIR+"tdv_ner_model.dat")

h1 "Binary Relation Detection"
puts <<~DOC
  Detect relationships betweens two entities, like:

    * PERSON was born in LOCATION
    * ORGANIZATION was founded in LOCATION
    * FILM was directed by PERSON

  There are 21 detectors for English. You can find them
  in the binary_relations directory in the model download.
DOC

h2 "Load a detector"

detector = Mitie::BinaryRelationDetector.new(MITIE_MODEL_DIR+"binary_relations/rel_classifier_organization.organization.place_founded.svm")

ap detector

h2 "And create a document"

doc = model.doc("Shopify was founded in Ottawa") # Github was bought by MicroSoft.

ap doc

h2 "Get relations"

ap detector.relations(doc)

expected = [{first: "Shopify", second: "Ottawa", score: 0.17649169745814464}]

error(expected)



h1 "Training"

h2 "Load an NER model into a trainer"

trainer = Mitie::BinaryRelationTrainer.new(model)

ap trainer

h2 "Add positive and negative examples to the trainer"

tokens = ["Shopify", "was", "founded", "in", "Ottawa"]
trainer.add_positive_binary_relation(tokens, 0..0, 4..4)
trainer.add_negative_binary_relation(tokens, 4..4, 0..0)

h2 "Train the detector"

detector = trainer.train

h2 "Save the detector"

detector.save_to_disk("tdv_binary_relation_detector.svm")

h1 "Text Categorization"

h2 "Load a model into a trainer"

trainer = Mitie::TextCategorizerTrainer.new(MITIE_MODEL_DIR+"total_word_feature_extractor.dat")

ap trainer

h2 "Add labeled text to the trainer"

trainer.add(%w[This is super cool],                       "positive")
trainer.add(%w[I think you are a nice guy],               "positive")
trainer.add(%w[You are a very lovely young lady],         "positive")
trainer.add(%w[Your product is cool],                     "positive")
trainer.add(%w[I like what you have done with the place], "positive")
trainer.add(%w[kiss like you mean it],                    "positive")

trainer.add(%w[I never want to see you again],            "negative")
trainer.add(%w[Your program crashes too often],           "negative")
trainer.add(%w[All I see is a spinning ball],             "negative")
trainer.add(%w[It costs too much],                        "negative")
trainer.add(%w[I'm worried about you ability to program], "negative")



h2 "Train the model"

model = trainer.train

h2 "Save the model"

model.save_to_disk("tdv_text_categorization_model.dat")

h2 "Load a saved model"

model = Mitie::TextCategorizer.new("tdv_text_categorization_model.dat")

h2 "Categorize text"

ap model.categorize(%w[What a super nice day])
ap model.categorize(%w[Here is a dime. Call your mother and tell her you will never be a good programmer.])
ap model.categorize(%w[You are not a very nice person.  I never want to see you again.])

