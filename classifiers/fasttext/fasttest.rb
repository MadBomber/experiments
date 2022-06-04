#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: fasttext.rb
##  Desc: Playing with the fasttext gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'fasttext'

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

cli_helper("Playing with the fasttext gem") do |o|

  o.bool    '-C', '--classify',   'Run Classify Examples',      default: false
  o.bool    '-V', '--vectorize',  'Run Vectorization Examples', default: false

  # o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  # o.int     '-i', '--int',    'example integer parameter',   default: 42
  # o.float   '-f', '--float',  'example float parameter',     default: 123.456
  # o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  # o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  # o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# Display the usage info
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

######################################################
# Main

at_exit do
  puts
  puts "\nDone."
  puts
end

ap configatron.to_h  if verbose? || debug?

if classify?

print "\n\n\n\m"
puts "="*80


h1 "Classification"
h2 "documents"

corpus = [
  "I love ham and carrots with peas and mashed potatoes",
  "Mashed potatoes are find",
  "peas can be hidden under mashed potatoes",
  "carrots are orange",
  "what word color is orange"
]

ap corpus

h2 "labels one per document"

labels  = [
            %w[love ham carrots peas mashed potatoes],
            %w[mashed potatoes fine],
            %w[peas hidden mashed potatoes],
            %w[carrots orange],
            %w[color pramge]
          ]

ap labels

h2 "Train a model"

classification_model = FastText::Classifier.new(
  # lr:                   0.1,  # learning rate
  # dim:                  100,  # size of word vectors
  # ws:                   5,    # size of the context window
  # epoch:                5,    # number of epochs
  # min_count:            1,    # minimal number of word occurences
  # min_count_label:      1,    # minimal number of label occurences
  # minn:                 0,    # min length of char ngram
  # maxn:                 0,    # max length of char ngram
  # neg:                  5,    # number of negatives sampled
  # word_ngrams:          1,    # max length of word ngram
  # pretrained_vectors:   nil,  # pretrained word vectors (.vec file)
  # autotune_metric:      "f1", # autotune optimization metric
  # autotune_predictions: 1,    # autotune predictions
  # autotune_duration:    300,  # autotune search time in seconds
  # autotune_model_size:  nil   # autotune model size, like 2M  #
  # loss:                 "softmax",  # loss function {ns, hs, softmax, ova}
  # bucket:               2000000,    # number of buckets
  # thread:               3,          # number of threads
  # lr_update_rate:       100,        # change the rate of updates for the learning rate
  # t:                    0.0001,     # sampling threshold
  #
  # label_prefix:         "__label__",  # label prefix
  #
  # verbose:              2,    # verbose
)

ap classification_model.fit(corpus, labels) # corpus can be a file name as a String
                                            # each line is a complete document

h2 "Get predictions"

ap classification_model.predict("who likes tractors?")

h2 "Save the model to a file"

ap classification_model.save_model("classification_model.bin")

h2 "Load the model from a file"

ap classification_model = FastText.load_model("classification_model.bin")

h2 "Evaluate the model"
# SNELL: what are x_text and y_test

x_test = "x_test.txt"    # file name?
y_test = "I do not know."   # file name?

ap classification_model.test(x_test)  #, y_test) # x_test can be a filename as a String

h2 "Get words and labels"

ap classification_model.words(  include_freq: true)
ap classification_model.labels( include_freq: true)

# Use include_freq: true to get their frequency

h2 "Search for the best hyperparameters"

x_valid = "x_valid.txt"         # looks like a file name?
y_valid = "y_valid.txt" # looks like a file name?

ap classification_model.fit(corpus, labels) #, autotune_set: [x_valid, y_valid])

h2 "Compress the model - significantly reduces size but sacrifices a little performance"
puts "takes a while so skipping it ..."
# ap classification_model.quantize
# ap classification_model.save_model("classification_model.ftz")

end # if classify?



##########################################

if vectorize?

print "\n\n\n\m"
puts "="*80




h1 "Word Representations"

h2 "Prep your data"

x = [
  "text from document one",
  "text from document two",
  "text from document three"
]

ap x

h2 "Train a model"

vector_model = FastText::Vectorizer.new(
  # model:          "skipgram",   # unsupervised fasttext model {cbow, skipgram}
  # lr:             0.05,         # learning rate
  # dim:            100,          # size of word vectors
  # ws:             5,            # size of the context window
  # epoch:          5,            # number of epochs
  # min_count:      5,            # minimal number of word occurences
  # minn:           3,            # min length of char ngram
  # maxn:           6,            # max length of char ngram
  # neg:            5,            # number of negatives sampled
  # word_ngrams:    1,            # max length of word ngram
  # loss:           "ns",         # loss function {ns, hs, softmax, ova}
  # bucket:         2000000,      # number of buckets
  # thread:         3,            # number of threads
  # lr_update_rate: 100,          # change the rate of updates for the learning rate
  # t:              0.0001,       # sampling threshold
  # verbose:        2             # verbose
)


ap vector_model.fit(x)  # x can be file name as a String
                        # each line in the file should be a document

h2 "Get nearest neighbors"

ap vector_model.nearest_neighbors("asparagus")

h2 "Get analogies"

vector_model.analogies("berlin", "germany", "france")

# Get a word vector

ap vector_model.word_vector("carrot")

h2 "Get a sentence vector"

ap vector_model.sentence_vector("sentence text")

h2 "Get words"

ap vector_model.words

h2 "Save the model to a file"

ap vector_model.save_model("vector_model.bin")

h2 "Load the model from a file"

ap vector_model = FastText.load_model("vector_model.bin")

h2 "Use continuous bag-of-words"

ap vector_model = FastText::Vectorizer.new(model: "cbow")

end # if vectorize?
