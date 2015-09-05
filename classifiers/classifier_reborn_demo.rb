#!/usr/bin/env ruby
# classifier_reborn_demo.rb

require 'classifier-reborn'

training_set = DATA.read.split("\n")
categories   = training_set.shift.split(',').map{|c| c.strip}

classifier = ClassifierReborn::Bayes.new categories

training_set.each do |a_line|
  next if a_line.empty? || '#' == a_line.strip[0]
  parts = a_line.strip.split(':')
  classifier.train(parts.first, parts.last)
end

puts classifier.classify "I hate bad words and you" #=> 'Uninteresting'
puts classifier.classify "I hate javascript" #=> 'Uninteresting'
puts classifier.classify "javascript is bad" #=> 'Uninteresting'

puts classifier.classify "all you need is ruby" #=> 'Interesting'
puts classifier.classify "i love ruby" #=> 'Interesting'

puts classifier.classify "which is better dogs or cats" #=> 'dog'
puts classifier.classify "what do I need to kill rats and mice" #=> 'cat'


__END__
Interesting, Uninteresting
interesting: here are some good words. I hope you love them
interesting: all you need is love
interesting: the love boat, soon we will bre taking another ride
interesting: ruby don't take your love to town

uninteresting: here are some bad words, I hate you
uninteresting: bad bad leroy brown badest man in the darn town
uninteresting: the good the bad and the ugly
uninteresting: java, javascript, css front-end html
#
# train categories that were not pre-described
#
dog: dog days of summer
dog: a man's best friend is his dog
dog: a good hunting dog is a fine thing
dog: man my dogs are tired
dog: dogs are better than cats in soooo many ways

cat: the fuzz ball spilt the milk
cat: got rats or mice get a cat to kill them
cat: cats never come when you call them
cat: That dang cat keeps scratching the furniture


