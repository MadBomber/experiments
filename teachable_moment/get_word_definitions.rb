#!/usr/bin/env ruby
# encoding: utf-8
# File: get_word_definitions.rb

require 'cli_helper'
include CliHelper


cli_helper 'Get definitions for words in a list' do |o|
  o.path '-f', '--file',        'File containing word list'
  o.path '-c', '--create-test', 'Create config file used in test generater'
  o.int  '-w', '--word-count',  'How many words to use on the test', default: 20
end


require 'wordnet'

if configatron.file.nil?
  words = %w{ 
    amputate    
    aptitude    
    beneficiary   
    boon      
    commiserate   
    garner      
    gratis      
    incapacitate  
    inception   
    magnanimous   
    myriad      
    practicable   
    remunerate    
    solicit     
    trite     
  }
else
  if configatron.file.exist?
    words = []
    configatron.file.read.split("\n").each do |a_line|
      next if a_line.start_with?('#')
      next if a_line.empty?
      words << a_line.split().select {|w| !w.start_with?('(')}
    end
  else
    error "File Does Not Exist: #{configatron.file}"
    abort_if_errors
  end
end

test_data = []


words.flatten.each do |word|

  puts "\n============="
  puts "== #{word}"
  lemmas = WordNet::Lemma.find_all(word)

  definitions = lemmas.map { |lemma| lemma.synsets }.flatten

  puts "Size: #{definitions.size}"

  definitions.each do |d|
    if d.gloss.include?(';')
      parts = d.gloss.split(';')
      parts.each do |p|
        unless p.include?(word)
          definition = p.strip
          puts definition
          test_data << [word, definition] unless definition.start_with?('"')
        end
      end
      next
    end
    puts d.gloss unless d.gloss.include?(word)
  end

end

puts

unless configatron.create_test.nil?
  if '.ini' == configatron.create_test.extname.to_s
    config_file = configatron.create_test
  else
    config_file = Pathname.bew(configatron.create_test.to_s+'.ini')
  end

  if config_file.exist?
    warning "File Already Exists: #{config_file}"
    abort_if_errors
  end

  CF = File.open(config_file, 'w')
  CF.puts "# #{config_file}"
  CF.puts "# Source: #{configatron.file}"
  CF.puts "\n[definitions]\n"
  test_data.sample(configatron.word_count).each do |entry|
    word        = entry.first
    definition  = entry.last
    CF.printf "%-20s= %s\n", word, definition
  end
  CF.close
end

__END__

The created config file for the test generater looks like this:

# header stuff

[definitions]
  
word1    = definition 1
word2    = definition 2

... etc.




__END__
lemma = WordNet::Lemma.find("fruit", :noun)
show lemma

lemma.synsets.each { |synset| puts synset.gloss }


 lemmas = WordNet::Lemma.find_all("fruit")
show lemmas

 synsets = lemmas.map { |lemma| lemma.synsets }
show synsets

 words = synsets.flatten
show words

words.each { |word| puts word.gloss }



__END__

#     data = Words::Wordnet.new
# or: data = Words::Wordnet.new(:tokyo) for the tokyo backend

# to specify a wordnet path Words::Words.new(:pure, '/path/to/wordnet')
# to specify the tokyo dataset Words::Words.new(:tokyo, :search, '/path/to/data.tct')

# Need to yum install wordnet wordnet-*
# you can use :pure or :tokyo cabinet-based data stores

data = Words::Wordnet.new(:pure, ENV['WORDNET_DB_PATH'])


# play with connections
assert data.connected?

data.close!

refute data.connected?

data.open!

assert data.connected?

assert_equal :pure, data.connection_type

# locate a word
lemma = data.find("bat")

assert_equal 'bat, noun/verb', lemma.to_s

assert_equal [:noun, :verb], lemma.available_pos.inspect

show lemma.synsets(:noun)   # or lemma.nouns

show lemma.noun_ids

assert lemma.verbs?

# specify a sense
sense  = lemma.nouns.last
sense2 = lemma.nouns[2]

assert_equal 'a club used for hitting a ball in various games',
                sense.gloss

assert_equal ["cricket bat", "bat"], sense2.words

show sense2.lexical_description

assert_equal 'Semantic hypernym relation between n02806379 and n03053474',
                sense.relations.first

show sense.relations(:hyponym)  # or sense.hyponyms

assert sense.hyponyms?

assert sense.relations.first.is_semantic?

assert_equal nil, sense.relations.first.source_word

show sense.relations.first.destination

refute sense.derivationally_related_forms.first.is_semantic?

assert_equal 'bat', sense.derivationally_related_forms.first.source_word

assert_equal 'bat', sense.derivationally_related_forms.first.destination_word

show sense.derivationally_related_forms.first.destination

if data.evocations? # check for evocation support
   # sense relevant evocations
   show data.find("broadcast").senses.first.evocations
   show data.find("broadcast").senses.first.evocations[1]
   show data.find("broadcast").senses.first.evocations[1][:destination].words
end

# methods with a question mark for the synset object
synset_mq = %w[
  antonyms?                      entailments?         member_of_this_domain_regions?  see_alsos?
  attributes?                    hypernyms?           member_of_this_domain_topics?   similar_tos?
  causes?                        hyponyms?            member_of_this_domain_usages?   substance_holonyms?
  derivationally_related_forms?  instance_hypernyms?  part_holonyms?                  substance_meronyms?
  domain_of_synset_regions?      instance_hyponyms?   part_meronyms?                  verb_groups?
  domain_of_synset_topics?       member_holonyms?     participle_of_verbs?
  domain_of_synset_usages?       member_meronyms?     pertainyms?
]

unless configatron.keyword.nil?
  keyword = data.find configatron.keyword
  if keyword.nil?
    puts "\nCan not find an entry for keyword: '#{configatron.keyword}'"
    puts "It is either mis-spelled or not in the word-net database."
  else
    keywords = [ configatron.keyword ]
    keywords << keyword.nouns.map{|n| n.words} if keyword.nouns?
    keywords << keyword.verbs.map{|v| v.words} if keyword.verbs?
    keywords = keywords.flatten.uniq.sort
    puts
    puts "The keyword '#{configatron.keyword}' has the following additional terms:"
    puts keywords.join(', ')
    puts
    puts 'Here are some other things to consider'
    puts
    keyword.senses.each do |s|
      s.hyponyms.each do |h|
        puts h.destination.words.flatten.uniq.sort.join(', ')
        puts h.destination.gloss
        puts
      end if s.hyponyms?
    end

    synset_mq.each do|m|
      keyword.synsets.each do |s|
        present = s.send(m.to_sym)
        if present
          puts "-"*42
          puts "#{m} true"
          m2 = m.gsub('?','')
          result = s.send(m2.to_sym)
          result.each do |r|
            puts ('- '*6)+"-"
            puts r.destination.gloss
            ap r.destination.words
            unless r.source_word.nil?  &&  r.destination_word.nil?
              puts " #{r.source_word} ---+==>> #{r.destination_word}"
            end
          end
        end # if present
      end # keyword.synsets.each do |s|
    end # synset_mq.each do|m|
  end # if keyword.nil?
end # unless $options[:keyword].nil?


data.close!
