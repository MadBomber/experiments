#!/usr/bin/env ruby
##########################################################
###
##  File: ngram.rb
##  Desc: Utilities classes for NLP n-gram analysis
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
##
##  NOTE: obtain the Brown corpus from here:
##
##          http://nltk.googlecode.com/svn/trunk/nltk_data/packages/corpora/brown.zip
#

require 'awesome_print'
require 'pp'
require 'pathname'

######################################################
# Local methods

class Ngram

  attr_accessor :options

  def initialize(target, options = { regex: / / })
    @target = target
    @options = options
  end

  def ngrams(n)
    @target.split(@options[:regex]).each_cons(n).to_a
  end

  def unigrams
    ngrams(1)
  end

  def bigrams
    ngrams(2)
  end

  def trigrams
    ngrams(3)
  end

end # end of class Ngram



class BrownCorpusFile

  def initialize(path)
    @path = path
  end

  ######################################################
  ## Split a file into an array of sentences
  ## where path is a path to a file in the Brown's corpus

  def sentences

    @sentences ||= File.open(@path) do |file|

      # each_with_object is simular to #inject
      # acc is the accumulator object being built

      file.each_line.each_with_object([]) do |line, acc|

        stripped_line = line.strip

        unless stripped_line.nil? || stripped_line.empty?
          acc << line.split(' ').map do |word|
            word.split('/').first
          end.join(' ')
        end

      end # of file.each_line.each_with_object([]) do |line, acc|

    end # of @sentences ||= File.open(@path) do |file|

  end # of def sentences

end # of class BrownCorpusFile

class Corpus

  def initialize(glob, klass)
    @glob = glob
    @klass = klass
  end

  def files
    @files ||= Dir[@glob].map do |file|
      @klass.new(file)
    end
  end

  def sentences
    files.map do |file|
      file.sentences
    end.flatten
  end

  def ngrams(n)
    sentences.map do |sentence|
      Ngram.new(sentence).ngrams(n)
    end.flatten(1)
  end

  def unigrams
    ngrams(1)
  end

  def bigrams
    ngrams(2)
  end

  def trigrams
    ngrams(3)
  end

end # of class Corpus



######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

bigrams = Ngram.new("The quick brown fox jumped over the lazy dog").bigrams
ap bigrams

corpus = Corpus.new('brown/c*', BrownCorpusFile)

ap corpus

capitals = ('A'..'Z')
results = Hash.new(0)

corpus.trigrams.each do |trigram|
  if trigram.first == "of" && capitals.include?(trigram[1].chars.first)
    result = [trigram[1]]

    if capitals.include?(trigram[2].chars.first)
      result << trigram[2]
    end

    results[result.join(' ')] += 1

  end
end

ap results


