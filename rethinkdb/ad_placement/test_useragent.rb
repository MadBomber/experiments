#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: test_useragent.rb
##  Desc: Test the UserAgent gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'cli_helper'
require 'useragent'

$options[:version] = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("__file_description__") do |o|

  o.path    '-p', '--path',   'path to test data'

end


if $options[:path].nil?
  error 'No test data file provided'
else
  unless $options[:path].exist?
    error 'Test data file does not exist.'
  end
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

ap $options  if verbose? || debug?

total_cnt  = 0
good_cnt   = 0
parse_err  = 0
to_h_err   = 0

$options[:path].readlines.each do |ua|
  total_cnt += 1
  next unless ua.start_with?('UA: ')
  ua = ua[4,99999].chomp

  begin
    ua_object = UserAgent.parse(ua)
  rescue Exception => e
    debug_me{[ :ua, :e]}
    parse_err += 1
    next
  end

  begin
    a_hash = ua_object.to_h
  rescue Exception => e
    puts
    puts ua
    puts e
    to_h_err += 1
    next
  end

  good_cnt += 1
end

puts

debug_me{[ :total_cnt, :good_cnt, :parse_err, :to_h_err ]}
