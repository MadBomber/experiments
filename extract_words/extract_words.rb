#!/usr/bin/env ruby
##########################################
## extract_words.rb
#
# This implementation is a brute force approach that relies upon
# access to a memory structure that contains valid English language
# words.  In this case its a Hash that is created by parsing a JSON
# file.  The current file used contains over 370K English words.
#
# A less memory intensive way of detecting word boundaries would
# be based upon rules.  The English language is a bery complex
# set of rules.  A review of any code libraries that implement
# sylable detection/counting in English words has a limited set of
# rules that might be reused for this kind of application.
#
# This problem is really the 1-deminision hidden word puzzle.  The
# difference is in not trying to find all the words that are present
# but just the ones that make the most sense.  The crux is how do
# you calculate "sense?"

require 'json'
require 'awesome_print'
require 'debug_me'
include DebugMe

# a utility model that knows whether a string is a valid
# English word.  This implementation is very memory intensive.
class Word
	def initialize
		# over 370K valid English words ... might be too big!
		@words = JSON.parse File.open('./words_dictionary.json').read
		clean_up_words
    begin_end_letters
	end

  # given the autorative collection of value English words
  # returns whether the give string parameter is a valid word
  def word?(a_string)
    !@words[a_string].nil?
  end

  # Is the character more likely to end a word?
  def ender?(a_character)
    @enders.include?(a_character)
  end

  # is the letter more likely to begin/start a word
  def beginner?(a_character)
    @beginners.include?(a_character)
  end

  private 

  # What I'm thinking about is when a single letter can be
  # used as either the last letter of the left word or the
  # beginning letter of the right word, which is more likely.
  def begin_end_letters
    counts = Hash.new{|h,k| h[k]=[0,0]}
    @words.keys.select{|key| key.size >= 3}.each do |key|
      a=key[0]
      z=key[key.size-1]
      counts[a] = [counts[a].first+1, counts[a].last]
      counts[z] = [counts[z].first, counts[z].last+1]
    end

    @enders     = ''
    @beginners  = ''

    counts.keys.each do |key|
      sum     = counts[key].first + counts[key].last
      p_ender = 100.0 * counts[key].last / sum
      p_begin = 100.0 * counts[key].first / sum
      # check   = p_ender + p_begin
      # puts "#{key}\t#{p_begin}\t#{p_ender}\t#{check}"
      @enders     += key if p_ender > 60.0
      @beginners  += key if p_begin > 60.0
    end
  end

	# get rid of some of those words ...
	def clean_up_words

		aeiou = %w[ a e i o u ]

		('a'..'z').each {|x| @words[x] = nil}
		%w[ a i ].each {|x| @words[x] = 1}

		@words.keys.select {|x| 2==x.size}.each do |x|
		  @words[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]))
		end

		@words.keys.select {|x| 3==x.size}.each do |x|
		  @words[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]) || aeiou.include?(x[2]))
		end

	end # def clean_up_words
end # class Word

Words = Word.new


def word?(a_string)
  Words.word?(a_string)
end

def ender?(a_character)
  Words.ender?(a_character)
end

def beginner?(a_character)
  Words.beginner?(a_character)
end


##################################
## Main Stuff
#
# There are at least two ways to approach finding hidden word
# boundaries in a string.  The first is to start on the left
# and collect valid words in a forward - left to right - fashion.
#
# Another approach is to start on the right - end - on collect
# in a backwards fashion - right to left - words.
#
# Whether forward or backward the object is the same to find the
# longest word possible.

def collect_words(a_string, char_indexes, direction=:forward)
  words = Array.new
  char_indexes.each do |edge_index|
    candidate = :forward == direction ? a_string[0..edge_index] : a_string[edge_index..a_string.size-1]
    words << candidate if word?(candidate)
  end

  return words
end


def determine_char_indexes(a_string, direction=:forward)
  if :forward == direction
    start         = 1
    stop          = a_string.size
    char_indexes  = (start..stop).to_a
  else
    start         = a_string.size - 1
    stop          = 0
    char_indexes  = (stop..start).to_a.reverse
  end

  return char_indexes
end


def find_valid_words(a_string, direction=:forward)
  return [] if a_string.empty?

  char_indexes  = determine_char_indexes(a_string, direction)
  words         = collect_words(a_string, char_indexes, direction)
  return words
end

# wgeb cikkectubg forward and an condition is reached inwhich
# there are characters left over that do no make up a word, backup
# to the previous word node and drop the longest form of a word
# in favor of a previous longest word.
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

# extract wirds ub a forward - left to right - fashion
def extract_words_1(a_string, result=[], backup=0)
  return result if a_string.empty?

  words = find_valid_words(a_string, :forward)

  unless words.empty?
    result   << words
    a_string  = a_string.delete_prefix(words.last)
    result    = extract_words_1(a_string, result)
  else
    if 0 == backup # do only one backtrace
      result, a_string = backtrace(result, a_string)
      result = extract_words_1(a_string, result, backup+1)
    else
      unless a_string.empty?
        # puts "debug: found no words in: #{a_string}"
        result << [a_string]
      end
    end
  end

  return result
end

=begin
  girlsdressupdollsinprettydresses
  girlsdressupdollsinpretty dresses
  girlsdressupdollsin pretty dresses
  girlsdressupdoll sin pretty dresses
  girlsdressupdoll sin pretty dresses
  girlsdressup doll sin pretty dresses
  girlsdres sup doll sin pretty dresses
  girlsd res sup doll sin pretty dresses
=end

# do a backtrace on the right to left - aka backwards direction
def backtrace_2(tree, a_string)
  last_node      = tree.last
  node_size      = last_node.size

  prev_tree_node = tree[tree.size-2]

  if node_size > 1
    curr = last_node[node_size-1] # left
    prev = last_node[node_size-2] # right
    restore_string = curr.delete_suffix(prev)
    a_string = a_string + restore_string

	puts <<~DEBUG

		Node Size:  #{node_size}
		Left/curr:  #{curr}
		Right/prev: #{prev}
		Restore:    #{restore_string}
		a_string:   #{a_string}

	DEBUG

    tree[tree.size-1] = last_node[0..node_size-2]
  
  end # if node_size > 1

  debug_me {[ :tree, :a_string ]}

  return tree, a_string
end

# extract words using the backwards - right to left - direction
def extract_words_2(a_string, result=[], backup=0)
  return result if a_string.empty?

  words = find_valid_words(a_string, :backward)

  unless words.empty?
    result   << words
    a_string  = a_string.delete_suffix(words.last)

    result    = extract_words_2(a_string, result)
  else
    if backup < 1
      result, a_string = backtrace_2(result, a_string)
      debug_me{[ :result, :a_string ]}
      result = extract_words_2(a_string, result, backup+1)
      debug_me{[ :result ]}
    else
      unless a_string.empty?
        # puts "debug: found no words in: #{a_string}"
        result << [a_string]
      end
    end
  end

  return result
end

# extract hidden words from a string using both forward
# and backward approaches.  Return results for each
# approach.
def extract_words(a_string)
  result = Array.new
  result_tree = extract_words_1(a_string)
  result << result_tree.map {|node| node.last}.join(' ')
  result_tree = extract_words_2(a_string)
  result << result_tree.map {|node| node.last}.reverse.join(' ')

  return result
end


##########################################################
## Lets do some testing

def show_begin_end_candidates(test_string)
  characters  = test_string.chars
  beginners   = ''
  enders      = ''
  characters.each do |a_char|
    beginners += beginner?(a_char) ? 'b' : ' '
    enders    += ender?(a_char) ? 'e' : ' '
  end
  return [ beginners, test_string, enders]
end


def test
  [
    'tellthetruthmister',
    'boysplaywithtrucks',
    'girlsliketodressupdollsinprettydresses'
  ].each do |test_string|
    puts "\n"+"="*65
    puts test_string

    results = extract_words(test_string)

    puts "\nForward:"
    puts show_begin_end_candidates(results.first).join("\n")

    puts "\nBackward"
    puts show_begin_end_candidates(results.last).join("\n")
  end
end

puts "\n\n"
test
puts "\n\n"

