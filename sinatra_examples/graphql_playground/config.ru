# config.ru
# Used with 'rackup'

require 'bundler/setup'

require './app'
run APP::App
