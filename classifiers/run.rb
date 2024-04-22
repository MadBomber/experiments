#!/usr/bin/env ruby
# experiments/classifiers/run.rb
#
# Usage:
#   ./run.rb *_test.rb

while !ARGV.empty?
  program = ARGV.shift

  puts
  puts "="*64
  puts "== Running #{program} .."
  puts
  puts `ruby ./#{program}`
  puts
  puts "== Done."
  puts "="*64
end

puts
puts "Done.  All tests have been completed."
puts
