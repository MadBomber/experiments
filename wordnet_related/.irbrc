require 'words'

$d = Words::Wordnet.new(:pure, Words::Wordnet.new(:pure, ENV['WORDNET_DB_PATH'])
