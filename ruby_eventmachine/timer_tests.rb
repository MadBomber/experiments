#!/bin/env ruby
require 'rubygems'
require 'eventmachine'

puts "cntl-c to quit."
puts "expect a period every second and a dollar sign every 5 seconds on stderr."

EventMachine::run {
  puts "Starting the run now: #{Time.now}"
  EventMachine::add_periodic_timer( 1 ) { $stderr.write "." } ## code block executes every second
  EventMachine::add_periodic_timer( 5 ) { $stderr.write "$" } ## block executes every 5 seconds

  EventMachine::add_timer 5, proc { puts "\nExecuting one-shot timer event: #{Time.now}" }
  EventMachine::add_timer( 10 ) { puts "\nExecuting one-shot timer event: #{Time.now}" }

}


