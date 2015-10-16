#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: definitions_test_maker.rb
##  Desc: Generate multiple choice and matching tests from
##        a definitions file
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("__file_description__") do |o|

  o.bool  '-c', '--choice', 'Generate Multiple Choice Test',  default: false
  o.bool  '-m', '--match', 'Generate Matching Test',  default: false
  o.path    '-t', '--test',   'Test File', default: Pathname.new('sample_test.ini')

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check you stuff; use error('some message') and warning('some message')

unless choice?  ||  match?
  error 'You must choose to have either a multiple choice, matching or both kinds of tests generated.'
end

unless configatron.test.exist?
  error "The specified test file does not exist:  #{configatron.test}"
end

abort_if_errors

cli_helper_process_config_file(configatron.test)

sample_size = 4 
sample_size = configatron.arguments.first.to_i unless configatron.arguments.empty?


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?


words = configatron.definitions.keys.map{|w| w.to_s}
definitions = configatron.definitions.values

max_word_size = -1
words.each do |w|
  max_word_size = w.size if w.size > max_word_size
end

max_word_size += 5


if choice?
  q=0
  words.each do |w|
    answers = definitions.sample(sample_size)
    unless answers.include?(definitions[q])
      answers.shift
      answers << definitions[q]
      answers.shuffle!
    end
    q += 1
    puts "\n\n#{q}). #{w} means ... "
    answers.each do |a|
      puts "\t[__] #{a}"
    end
  end
end

if match?
  puts "\n\n\n"
  q=0
  words.each do |w|
    q += 1
    printf "%2d). %s means #{'.'*(max_word_size-w.size)} ______\n\n", q, w
  end
#
  puts "\n\n\n"
  q=0
  definitions.shuffle.each do |d|
    q += 1
    puts "#{q}). #{d}"
  end
end


