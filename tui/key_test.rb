#!/usr/bin/env ruby

require 'tty-reader'
require 'tty-cursor'

puts "Key Test - press keys to see what codes are detected (ESC to quit):"
puts "Try arrow keys, Home, End, Delete, etc."

reader = TTY::Reader.new
cursor = TTY::Cursor

loop do
  key = reader.read_keypress
  
  print cursor.column(1)
  print "Key pressed: #{key.inspect} (class: #{key.class})"
  
  if key == "\e"
    puts "\nExiting..."
    break
  end
  
  puts
end