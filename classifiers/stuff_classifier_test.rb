#!/usr/bin/env ruby
###################################################
###
##  File: stuff_classifier_test.rb
##  Desc: simple classifier
#
#
# The stuff_classifier gem is a good candidate for the
# crystalruby experiment.




# Stuff Classifier has an error so this fixes it
class File
  class << self
    alias_method :exists?, :exist?
  end
end

require 'date'
require 'pathname'

require 'amazing_print'

require 'stuff-classifier'

def assert(expected, got)
  if expected == got
    puts "Good: got #{got}"
  else
    puts "Expected: #{expected} (#{expected.class})   Got: #{got} (#{got.class})  Where: #{caller}"
  end
end

data_set_name = 'Cats or Dogs'

training_db_path    = Pathname.new(__FILE__) + '..' + 'stuff_classifier.db'
previously_trained  = training_db_path.exist?

store = StuffClassifier::FileStorage.new(training_db_path.to_s)

# global setting
StuffClassifier::Base.storage = store

# or alternative local setting on instantiation, by means of an
# optional param ...
# cls = StuffClassifier::Bayes.new(data_set_name, :storage => store)


# for the naive bayes implementation
cls = StuffClassifier::Bayes.new(data_set_name)

# for the Tf-Idf based implementation
# cls = StuffClassifier::TfIdf.new("Cats or Dogs")

# these classifiers use word stemming by default, but if it has weird
# behavior, then you can disable it on init:
# cls = StuffClassifier::TfIdf.new(data_set_name, :stemming => false)

# also by default, the parsing phase filters out stop words, to
# disable or to come up with your own list of stop words, on a
# classifier instance you can do this:
# cls.ignore_words = [ 'the', 'my', 'i', 'dont' ]


if previously_trained
  puts "Previously trained!"
  cls = StuffClassifier::TfIdf.open(data_set_name)

  # to start fresh, deleting the saved training data for this classifier
  # StuffClassifier::Bayes.new(data_set_name, :purge_state => true)

  puts "Using previously trained classification db.  To retrain"
  puts "delete the file: #{training_db_path}"

else
  puts "training the difference between cats and dogs..."

  cls = StuffClassifier::TfIdf.new(data_set_name)

  # Training the classifier:
  cls.train(:dog, "Dogs are awesome, cats too. I love my dog")
  cls.train(:cat, "Cats are more preferred by software developers. I never could stand cats. I have a dog")
  cls.train(:dog, "My dog's name is Willy. He likes to play with my wife's cat all day long. I love dogs")
  cls.train(:cat, "Cats are difficult animals, unlike dogs, really annoying, I hate them all")
  cls.train(:dog, "So which one should you choose? A dog, definitely.")
  cls.train(:cat, "The favorite food for cats is bird meat, although mice are good, but birds are a delicacy")
  cls.train(:dog, "A dog will eat anything, including birds or whatever meat even my meat")
  cls.train(:cat, "My cat's favorite place to purr is on my keyboard")
  cls.train(:dog, "My dog's favorite place to take a leak is the tree in front of our house")

end

# after training is done, to persist the data ...
cls.save_state


# or you could just do this:
#StuffClassifier::Bayes.open(data_set_name) do |cls|
#  # when done, save_state is called on END
#end


# And finally, classifying stuff:

puts "Testing statement classification."

assert :cat, cls.classify("This test is about cats.").to_sym
assert :cat, cls.classify("I hate ...").to_sym
assert :cat, cls.classify("The most annoying animal on earth.").to_sym
assert :cat, cls.classify("The preferred company of software developers.").to_sym
assert :cat, cls.classify("My precious, my favorite!").to_sym
assert :cat, cls.classify("Get off my keyboard!").to_sym
assert :cat, cls.classify("Kill that bird!").to_sym

assert :dog, cls.classify("This test is about dogs.").to_sym
assert :dog, cls.classify("Cats or Dogs?").to_sym
assert :dog, cls.classify("What pet will I love more?").to_sym
assert :dog, cls.classify("Willy, where the heck are you?").to_sym
assert :dog, cls.classify("I like big dogs and I cannot lie.").to_sym
assert :dog, cls.classify("Why is the front door of our house open?").to_sym
assert :dog, cls.classify("Who is eating my meat?").to_sym
