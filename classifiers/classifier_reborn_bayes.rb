#!/usr/bin/env ruby

require 'kick_the_tires'
include KickTheTires

require 'classifier-reborn'

classifier = ClassifierReborn::Bayes.new 'Interesting', 'Uninteresting'
classifier.train_interesting "here are some good words. I hope you love them"
classifier.train_uninteresting "here are some bad words, I hate you"

assert_equal 'Uninteresting', classifier.classify("I hate bad words and you") # returns 'Uninteresting'

classifier_snapshot = Marshal.dump classifier
# This is a string of bytes, you can persist it anywhere you like

show classifier_snapshot

File.open("classifier.dat", "w") {|f| f.write(classifier_snapshot) }
# Or Redis.current.save "classifier", classifier_snapshot

# This is now saved to a file, and you can safely restart the application
data = File.read("classifier.dat")
# Or data = Redis.current.get "classifier"
trained_classifier = Marshal.load data

assert_equal 'Interesting', trained_classifier.classify("I love") # returns 'Interesting'

