#!/bin/env ruby
#############################################################
###
##  File: file_watcher.rb
##  Desc: Watch a file for system-level events
#

require 'rubygems'
require 'eventmachine'
require 'pathname'
require 'pp'

if 1 > ARGV.length || '-' == ARGV[0][1]

  puts <<EOF

Watch a file for system-level events.

Usage: #{Pathname.new($0).basename} path_to_file

  Where:

    path_to_file    is the /path/to/the/file

This capability is not available on eventmachine releases
prior to 0.12.7.

EOF

  exit -1

end

file_to_watch = ARGV[0]

module FileEventHandler

  def file_modified
    puts "#{path} modified"
  end

  def file_moved
    puts "#{path} moved"
  end

  def file_deleted
    puts "#{path} deleted"
  end

  def unbind
    puts "#{path} monitoring ceased"
  end

end

EM.run {
  EM.watch(file_to_watch, FileEventHandler)
}

puts "Done."

