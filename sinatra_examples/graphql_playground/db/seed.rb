# db/seed.rb

require '../app'

Speaker.create(name: 'John', twitter_handle: 'johnruby', bio: 'This is John\'s bio', talk_title: 'How to bootstrap a sinatra application')

Speaker.create(name: 'Jacob', twitter_handle: 'jacob-ruby', bio: 'This is Jacob\'s bio', talk_title: 'Introduction to graphql')

