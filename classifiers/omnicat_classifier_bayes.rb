#!/usr/bin/env ruby

require 'kick_the_tires'
include KickTheTires

#require 'omnicat'
require 'omnicat/bayes'

OmniCat.configure do |config|
  # you can enable auto train mode by :unique or :continues
  # unique: only uniq docs will be added to training docs on prediction
  # continues: always add docs to training docs on prediction
  config.auto_train = :off
  config.exclude_tokens = ['something', 'anything'] # exclude token list
  config.token_patterns = {
    # exclude tokens with Regex patterns
    minus: [/[\s\t\n\r]+/, /(@[\w\d]+)/],
    # include tokens with Regex patterns
    plus: [/[\p{L}\-0-9]{2,}/, /[\!\?]/, /[\:\)\(\;\-\|]{2,3}/]
  }
end

# If you need to change strategy on runtime, you should prefer this inialization
#bayes = OmniCat::Classifier.new(OmniCat::Classifiers::Bayes.new)

# If you only need to use only Bayes classification, then you can use
bayes = OmniCat::Classifiers::Bayes.new

bayes.add_category('positive')
bayes.add_category('negative')

bayes.train('positive', 'great if you are in a slap happy mood .')
bayes.train('negative', 'bad tracking issue')

#bayes.untrain('positive', 'great if you are in a slap happy mood .')
#bayes.untrain('negative', 'bad tracking issue')


bayes.train_batch('positive', [
  'a feel-good picture in the best sense of the term...',
  'it is a feel-good movie about which you can actually feel good.',
  'love and money both of them are good choises'
])
bayes.train_batch('negative', [
  'simplistic , silly and tedious .',
  'interesting , but not compelling . ',
  'seems clever but not especially compelling'
])

=begin
bayes.untrain_batch('positive', [
  'a feel-good picture in the best sense of the term...',
  'it is a feel-good movie about which you can actually feel good.',
  'love and money both of them are good choises'
])
bayes.untrain_batch('negative', [
  'simplistic , silly and tedious .',
  'interesting , but not compelling . ',
  'seems clever but not especially compelling'
])
=end

result = bayes.classify('I feel so good and happy')

show result
show result.to_hash
show result.top_score
show result.top_score.to_hash


result = bayes.classify_batch(
  [
    'the movie is silly so not compelling enough',
    'a good piece of work'
  ]
)

show result
#show result.to_hash
#show result.top_score
#show result.top_score.to_hash


classifier_db = bayes.to_hash

show classifier_db


bayes_2 = OmniCat::Classifiers::Bayes.new(classifier_db)

result = bayes_2.classify('best senses')

show result
show result.to_hash
show result.top_score
show result.top_score.to_hash
