#!/usr/bin/env ruby
#####################################################
###
##  File: lurn_test.rb
#

require 'amazing_print'

require 'lurn'

data = [
  ['computers', 'ruby is a great programming language'],
  ['sports',    'the giants recently won the world series'],
  ['computers', 'java is a compiled programming language'],
  ['sports',    'the jets are a football team']
]

puts "\nTraining Data Set"
puts

data.each do |example|
  puts example.last
  puts "* labeled as: #{example.first}"
end

puts

labels    = data.map{|example| example.first }
documents = data.map{|example| example.last }


# vectorizers take raw data and transform it to a set of features that our
# model can understand - in this case an array of boolean values representing
# the presence or absence of a word in text
vectorizer = Lurn::Text::BernoulliVectorizer.new
vectorizer.fit(documents)
vectors = vectorizer.transform(documents)

model = Lurn::NaiveBayes::BernoulliNaiveBayes.new
model.fit(vectors, labels)


test_samples = [
  ['computers', 'programming is fun'],
  ['computers', 'FORTRAN is an old language']
]

puts

test_samples.each  do |sample|
  expecting = sample.first
  testing   = sample.last

  new_vectors = vectorizer.transform([testing])
  puts "  Testomg: #{testing}"
  puts "Expecting: #{expecting}"
  got = model.max_class(new_vectors.first)
  puts "      Got: #{got}"
  puts "   Result: #{expecting==got ? 'passed' : 'failed'}"
  puts
end

puts
puts "model ..."
ap model
