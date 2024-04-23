#!/usr/bin/env ruby
# experiments/classifiers/auto_organization/organizer.rb
#
# Desc: what a directory for new files.  Move the new files into
#       sub-directories basedupon their content.  The files in
#       a sub-directory should be closely related through an
#       unguided classification system.

class NilClass
  def to_s
    "Null"
  end
end

puts "auto-organizer"

require 'debug_me'
include DebugMe

require 'pathname'
require 'listen'
require 'fileutils'
require 'classifier-reborn'

class Organizer
  WATCHED_DIR     = './watched'
  CATEGORIES_DIR  = './categories'


  def initialize
    # Get the manually generated topics
    # topics  = Pathname.new(CATEGORIES_DIR).children
    #             .select{|c| c.directory?}
    #             .map{   |c| c.basename.to_s}

    # Set up the classifier
    @classifier = ClassifierReborn::Bayes.new # (topics)

    # Here you would train the @classifier with sample data
    # For simplicity, using hard-coded example content
    # train_classifier # The supervised approach

    @listener = Listen.to(WATCHED_DIR) do |modified, added, removed|
      unless added.empty?
        added.each do |new_file|
          classify_and_move_file(new_file)
        end
      end
    end
  end


  def start
    puts "Monitoring directory: #{WATCHED_DIR}"
    @listener.start
    sleep
  end


  ##############################################
  private

  # The supervised approach is to train the classification model
  # if a model exists then load it.  May need to do a retrain step.
  #
  def train_classifier
    # For each sub-directory, train the classifier on the
    # content in that sub-directory unless a model already
    # exists then just load the classifier model.
    #
    # Pathname.new(CATEGORIES_DIR).children do |sub_directory|
    #   next unless sub_directory.directory?
    #   topic = sub_directory.basename.to_s
    #   sub_directory.children.each do |doc|
    #     next if doc.directory?
    #     @classifier.train(topic, doc.read)
    #   end
    # end
  end


  def classify_content(content)
    # Using the classifier to categorize content
    @classifier.classify(content)
  end


  def classify_and_move_file(file_path)
    content     = File.read(file_path)
    category    = classify_content(content)
    target_dir  = File.join(CATEGORIES_DIR, category)

    FileUtils.mkdir_p(target_dir) unless File.exist?(target_dir)

    file_name   = File.basename(file_path)
    target_path = File.join(target_dir, file_name)

    FileUtils.mv(file_path, target_path)
    puts "Moved #{file_name} to #{target_path}"
  end
end

Organizer.new.start


__END__


# Assuming we have a collection of text documents:
texts = [
  "Ruby on Rails is a server-side web application framework written in Ruby.",
  "Python is a widely used high-level programming language for general-purpose programming.",
  "JavaScript is predominantly used to enhance web pages for a more interactive user experience.",
  "Machine learning involves algorithms and statistical models that computer systems use to perform tasks without explicit instructions.",
  "Deep learning is a subset of machine learning in artificial intelligence that has networks capable of learning unsupervised from data that is unstructured or unlabeled."
]

# Initialize LSI
lsi = ClassifierReborn::LSI.new(auto_rebuild: true)

# Add documents to LSI
texts.each_with_index do |text, index|
  lsi.add_item text, "Text #{index+1}"
end

# Number of topics to extract, adjust this according to your needs
num_topics = 3

# Output the identified topics
puts "Identified topics:"
lsi.lsi.keys.take(num_topics).each_with_index do |key, index|
  puts "Topic #{index + 1}: #{key.inspect}"
end

# For each topic, we can also list documents that are most related
lsi.lsi.keys.take(num_topics).each_with_index do |key, index|
  puts "\nRelated documents to Topic #{index + 1}: #{key.inspect}"
  related_documents = lsi.search_related(key)
  
  related_documents.each do |doc|
    puts doc.first
  end
end

