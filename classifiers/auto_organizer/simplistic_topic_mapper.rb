#!/usr/bin/env ruby
# simplistic_topic_mapper.rb
#
# This is based upon the assumption that topics are nouns
# and noun phrases.  Using a part of speech tagger collect
# collect all the nouns and noun phrases.  Count their
# occurrence.  The ones with the highest counts are chosen
# as topics.
#
# This sucks!


require 'pathname'

require 'debug_me'
include DebugMe

require 'engtagger'

STOPWORDS = %w[
  a about above after again against all am an and any are aren't as at be because been 
  before being below between both but by can't cannot could couldn't did didn't do does 
  doesn't doing don't down during each few for from further had hadn't has hasn't have 
  haven't having he he'd he'll he's her here here's hers herself him himself his how 
  how's i i'd i'll i'm i've if in into is isn't it it's its itself let's me more most 
  mustn't my myself no nor not of off on once only or other ought our ours ourselves 
  out over own same shan't she she'd she'll she's should shouldn't so some such than 
  that that's the their theirs them themselves then there there's these they they'd 
  they'll they're they've this those through to too under until up very was wasn't we 
  we'd we'll we're we've were weren't what what's when when's where where's which while 
  who who's whom why why's with won't would wouldn't you you'd you'll you're you've 
  your yours yourself yourselves
  def class module end if else elsif case when while do until for break next redo retry
  in unless return yield self true false nil and or not super alias defined? begin rescue
  ensure end __LINE__ __FILE__ __ENCODING__
].freeze



def extract_topics_simple(document_content, top_n: 5)
  # Initialize the EngTagger
  tagger = EngTagger.new

  # Tag the text
  tagged = tagger.add_tags(document_content)

  # Extract nouns and noun phrases
  nouns = tagger.get_nouns(tagged)
  phrases = tagger.get_noun_phrases(tagged)

  # Combine nouns and noun phrases, with a simple count for frequency
  word_counts = Hash.new(0)
  nouns.each do |noun, count|
    word_counts[noun] += count unless STOPWORDS.include?(noun.downcase)
  end
  phrases.each do |phrase, count|
    # We consider the phrase as a stop word if all words in the phrase are stop words
    all_stopwords = phrase.split.all? { |word| STOPWORDS.include?(word.downcase) }
    word_counts[phrase] += count unless all_stopwords
  end

  # Select the top N topics based on frequency
  topics = word_counts.sort_by { |_word, count| -count }.first(top_n).to_h

  debug_me {
    [
      :word_counts,
      :topics
    ]
  }

  # Output the topics for inspection
  topics
rescue => e
  puts "Error: #{e}"
  []
end

# Example usage
document_content = Pathname.new(ARGV.shift).read

topics = extract_topics_simple(document_content, top_n: 5)
topics.each { |topic, count| puts "#{topic}: #{count}" }

