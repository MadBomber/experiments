#!/usr/bin/env ruby
# test_stdin_reading.rb

require 'debug_me'
include DebugMe

require 'io/console'
require 'timeout_block'

stdin_stream = IO.open(STDIN.fileno)

puts "Start typing (or dictate) text. Press CTRL+C to exit."

$result = ""

loop do
  # Read input from STDIN in a non-blocking manner
  begin
    input = timeout_block(5) { stdin_stream.read_nonblock(1000) }
    
    debug_me(header: false){[ :input ]} 

    # If input is not nil or empty, process it
    unless input.nil? || input.empty?
      print "Input: #{input}"
      $result << input
    end

  rescue EOFError, Errno::EAGAIN
    # Handle closing or temporary unavailability
    next
  end
end

puts
puts "The Result: #{$result}"
