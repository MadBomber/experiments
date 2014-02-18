#!/usr/bin/env ruby
#
#   Generate some markovian chainery.  Optionally provide a first word.


require 'json'
require 'awesome_print'
require 'pathname'

analysis = Pathname.new(__FILE__).realpath.parent + 'analysis.txt'

corpus = JSON.parse(IO.read(analysis))

max_paragraph_count = rand(3)+2

max_paragraph_count.times do

  word = ( ARGV[0] || corpus[""].keys[ Random.rand(corpus[""].length) ] ) #.downcase
  output = "#{word} "

  sentence_count = 0
  max_sentence_count = rand(4)+2

  while sentence_count < max_sentence_count do

    data = corpus[word]

    # Load a weighted array with candidates for next word
    list = []
    data.each do |k, v|
        v.to_i.times { list.push(k) }
    end

    word = list[Random.rand(list.length)]

    output += "#{word} "

    sentence_count += 1 if '.' == word[word.length-1]

  end

  output.gsub!(" i ", " I ")
  output.gsub!("god", "God")
  output.gsub!("jesus", "Jesus")
  output.gsub!("christ", "Christ")
  output.gsub!("lord", "Lord")

  puts
  puts output

end

puts

