#!/usr/bin/env ruby
##########################################
## extract_words.rb

require 'json'
require 'awesome_print'

# over 370K valid English words ... might be too big!
W = JSON.parse File.open('./words_dictionary.json').read

# get rid of some of those words ...

aeiou = %w[ a e i o u ]

('a'..'z').each {|x| W[x] = nil}
%w[ a i ].each {|x| W[x] = 1}

W.keys.select {|x| 2==x.size}.each do |x|
  W[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]))
end

W.keys.select {|x| 3==x.size}.each do |x|
  W[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]) || aeiou.include?(x[2]))
end


def backtrace(tree, a_string)
  last_node = tree.last
  node_size = last_node.size
  if node_size > 1
    curr = last_node[node_size-1]
    prev = last_node[node_size-2]

    restore_string = curr[prev.size..]
    a_string = restore_string + a_string
    tree[tree.size-1] = last_node[0..node_size-2]
  end

  return tree, a_string
end


def find_valid_words(a_string)
  words = []
  (1..a_string.size).each do |ending|
    candidate = a_string[0..ending]
    words << candidate if W[candidate]
  end
  return words
end


def extract_words(a_string, result=[], backup=0)
  words = find_valid_words(a_string)

  unless words.empty?
    result   << words
    a_string  = a_string[words.last.size..]
    result    = extract_words(a_string, result)
  else
    if 0 == backup # do only one backtrace
      result, a_string = backtrace(result, a_string)
      result = extract_words(a_string, result, backup+1)
    else
      unless a_string.empty?
        puts "debug: found no words in: #{a_string}"
        result << [a_string]
      end
    end
  end

  return result
end


%w[
  tellthetruthmister
  boysplaywithtrucks
  girlsdressupdollsinprettydresses
].each do |test_string|
  puts "\nTesting with: #{test_string}"
  result_tree = extract_words(test_string)
  result = result_tree.map {|node| node.last}
  puts "RESULT: #{result.join(' ')}"
  ap result_tree
end

puts
