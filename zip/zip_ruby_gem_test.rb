#!/usr/bin/env ruby
##########################################################
###
##  File: zip_ruby_gem_test.rb
##  Desc: Testing the zip_ruby gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'pathname'

require 'zipruby'

pgm_name = Pathname.new(__FILE__).basename

usage = <<EOS

Testing the zip_ruby gem

Usage: #{pgm_name} options

Where:

  options               Do This
  -h or --help          Display this message

EOS

if ARGV.empty?  or  ARGV.include?('-h')  or  ARV.include?('--help')
  puts usage
  exit
end

# Check command line for Problems with Parameters

errors = []

# ...

unless errors.empty?
  puts
  puts "Correct the following errors and try again:"
  puts
  errors.each do |e|
    puts "\t#{e}"
  end
  puts
  exit(1)
end

######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

GC::Profiler.enable

before_stats  = ObjectSpace.count_objects
start         = Time.now

Zip::Archive.open("test.zip", Zip::CREATE) do |z|
  Dir["**/*"].each do |file|
    z.add_file file, file
  end
end

puts "Total time: #{Time.now - start}"
after_stats = ObjectSpace.count_objects

puts "[GC Stats] #{before_stats[:FREE] - after_stats[:FREE]} new allocated objects."


