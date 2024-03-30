#!/usr/bin/env ruby
# read_from_cli_pipe.rb
#
# Example:
#   echo "Hello World" | ./read_from_cli_pipe.rb
# or
#   ./read_from_cli_pipe.rb
#   Hello World<cr>
#   <control-D>
#
# unix pipes are just STDIN and STDOUT

puts "waiting for input from $stdin ie the pipe ..."
puts "on in the absence of a pipe from the keyboard whose"
puts "input should be terminated with a control-D"
puts

input_text = $stdin.read.chomp

reversed_text = input_text.reverse

puts reversed_text

