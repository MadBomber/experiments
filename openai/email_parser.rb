#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: email_parser.rb
##  Desc: parse an email with openAI
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
# See: https://dev.to/kanehooper/creating-an-ai-email-parser-using-ruby-and-openai-gpt-3-1mb4?ck_subscriber_id=791584073
#

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

require 'ruby-openai'

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("parse an email with openAI") do |o|

  o.bool    '-b', '--bool',   'example boolean parameter',   default: false
  o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  o.int     '-i', '--int',    'example integer parameter',   default: 42
  o.float   '-f', '--float',  'example float parameter',     default: 123.456
  o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

configatron.input_files = get_pathnames_from( configatron.arguments, '.txt')

if configatron.input_files.empty?
  error 'No text files were provided'
end

abort_if_errors


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

stub = <<EOS


   d888888o. 8888888 8888888888 8 8888      88 8 888888888o
 .`8888:' `88.     8 8888       8 8888      88 8 8888    `88.
 8.`8888.   Y8     8 8888       8 8888      88 8 8888     `88
 `8.`8888.         8 8888       8 8888      88 8 8888     ,88
  `8.`8888.        8 8888       8 8888      88 8 8888.   ,88'
   `8.`8888.       8 8888       8 8888      88 8 8888888888
    `8.`8888.      8 8888       8 8888      88 8 8888    `88.
8b   `8.`8888.     8 8888       ` 8888     ,8P 8 8888      88
`8b.  ;8.`8888     8 8888         8888   ,d8P  8 8888    ,88'
 `Y8888P ,88P'     8 8888          `Y88888P'   8 888888888P


EOS

puts stub

