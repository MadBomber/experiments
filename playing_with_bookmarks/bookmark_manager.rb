#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: bookmark_manager.rb
##  Desc: Manage bookmarks from browsers
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
=begin 

From FireFox there are two ways to extract bookmarks for external 
manipulation.  One is to export the bookmarks as an HTML file.  The 
other is to backup the bookmarks to a JSON file with a date stamp as
part of its file name.

The backup to JSON file extracts the most information about the bookmarks.
So lets explore what we can do with the file.

date-time fields can be converted to DateTime objects using:

require 'date'
date_added = "1457976618437000"
DateTime.strptime(date_added[0,13],'%Q')

This JSON file should contain sufficient data to look at some
clustering of the bookmarks.  Could start simply with the
URL and cluster the bookmarks together from the same domain.

Next step would be to add in the title and any annos.value text
available.

=end

require 'date'
require 'ffi_yajl'

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'


json_path = Pathname.pwd + 'bookmarks-2016-03-18.json'


HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("__file_description__") do |o|

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
puts;puts;puts;

a_hash = FFI_Yajl::Parser.parse( json_path.read )

ap a_hash

