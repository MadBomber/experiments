#!/usr/bin/env ruby -w
# simple_client.rb
# A simple DRb client

require 'drb'

DRb.start_service

# attach to the DRb server via a URI given on the command line
remote_array = DRbObject.new nil, ARGV.shift

puts remote_array.size

remote_array << 1

puts remote_array.size