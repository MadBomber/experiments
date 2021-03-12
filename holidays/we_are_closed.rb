#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: we_are_closed.rb
##  Desc: Playing with Holidays
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'date'
require 'string-similarity'

require 'active_support/all'
require 'chronic'
require 'feriados'
require 'holidays'
# require 'ice_cube'
# require 'montrose'


require 'amazing_print'

require 'debug_me'
include DebugMe

require 'tty-table'

dates_closed = <<~DATA.split("\n")
  # Start with Common ways to express month and day
  12/31
  1/1
  2/28
  2/29
  2/30
  6/3
  7/4

  01/1
  02/28
  02/29
  02/30
  06/3
  07/4

  01/01
  04/25
  05/16
  06/03
  07/04
  10/17


  # adding some spaces

  12 / 31
  1 / 1
  2 / 28
  2 / 29
  2 / 30

  12 /31
  1 /1
  2 /28
  2 /29
  2 /30

  12/ 31
  1/ 1
  2/ 28
  2/ 29
  2/ 30

  # Addomg sp,e ;eadomg zerps

  01 / 01
  02 / 28
  02 / 29
  02 / 30

  01 /01
  02 /28
  02 /29
  02 /30

  01/ 01
  02/ 28
  02/ 29
  02/ 30

  # Looking at month day year with leading spaces

    13/45/66
    12/32/2066
    12/31/66
    12/31/1966
    12/31/2066

  # putting the day first then the month
  # which is ambigious

  31/12
  28/2
  29/2
  30/2
  3/6

  # Switch to using "-" with between month and day
  12-31
  1-1
  2-28
  2-29
  2-30
  6-3
  7-4

  01-1
  02-28
  02-29
  02-30
  06-3
  07-4

  01-01
  04-25
  05-16
  06-03
  07-04
  10-17


  # adding some spaces

  12 - 31
  1 - 1
  2 - 28
  2 - 29
  2 - 30

  12 -31
  1 -1
  2 -28
  2 -29
  2 -30

  12- 31
  1- 1
  2- 28
  2- 29
  2- 30

  # Addomg sp,e ;eadomg zerps

  01 - 01
  02 - 28
  02 - 29
  02 - 30

  01 -01
  02 -28
  02 -29
  02 -30

  01- 01
  02- 28
  02- 29
  02- 30

  # Looking at month day year with leading spaces

    13-45-66
    12-32-2066
    12-31-66
    12-31-1966
    12-31-2066

  # putting the day first then the month
  # which is ambigious

  31-12
  28-2
  29-2
  30-2
  3-6


  # Use some abbreviations and leading spaces

    dec 31
    jan 1
    feb 28
    feb 29
    feb 30
    jun    3rd
    jul 4th
    dec 25th

    31st of dec
    1st of jan
    28th of feb
    29th of feb
    30th of feb
    3rd of jun
    4th of jul
    25th of dec

    december 31
    january 1
    feburary 28
    feburary 29
    feburary 30
    july 4th
    decimal 25th

  # ordinal day in month

  # missing keyword "in"

  1st monday  november
  2nd tuesday  november
  3rd wednesday  november
  4th thursday  november
  5th friday  november
  6th friday  november
  1st monday  nov
  2nd tuesday  nov
  3rd wednesday  nov
  4th thursday  nov
  5th friday  nov
  6th friday  nov
  1st mon  nov
  2nd tue  nov
  3rd wed  nov
  4th thur  nov
  5th fri  nov
  6th fri  nov

  # using keyword "in"

  1st monday in november
  2nd tuesday in november
  3rd wednesday in november
  4th thursday in november
  5th friday in november
  6th friday in november
  1st monday in nov
  2nd tuesday in nov
  3rd wednesday in nov
  4th thursday in nov
  5th friday in nov
  6th friday in nov
  1st mon in nov
  2nd tue in nov
  3rd wed in nov
  4th thur in nov
  5th fri in nov
  6th fri in nov

  4th    thursday    in    november

  1st monday      in november
  2nd tuesday     in november
  3rd wednesday   in november
  4th thursday    in november
  5th friday      in november
  6th friday      in november
  1st monday      in nov
  2nd tuesday     in nov
  3rd wednesday   in nov
  4th thursday    in nov
  5th friday  in nov
  6th friday  in nov
  1st mon     in nov
  2nd tue     in nov
  3rd wed     in nov
  4th thur    in nov
  5th fri     in nov
  6th fri     in nov

  # named official and informal holidays

  thanksgiving
  thanksgiving day
  thanksgiving friday
  black friday
  cyber monday

  christmas
  christmas eve
  christmas day

  last day of december
  new year's eve
  new year's day
  new years
  new years day

  canada day
  independance day

  good friday
  easter
  easter sunday
  easter monday

  vetrans' day
  vetrans day
  veterans' day
  veterans day
  vetrans'
  vetrans

  labor day
  labour day

  # full exact names of the holidays

    April Fool's Day
    Armed Forces Day
    Canada Day
    Christmas Day
    Earth Day
    Easter Monday
    Easter Sunday
    Father's Day
    Good Friday
    Groundhog Day
    Halloween
    Independence Day
    Labor Day
    Labour Day
    Martin Luther King, Jr. Day
    Memorial Day
    Mother's Day
    New Year's Day
    Presidents' Day
    St. Patrick's Day
    Thanksgiving
    Valentine's Day
    Veterans Day

  xyzzy
DATA


from  = Date.civil(2021,1,1)
to    = Date.civil(2022,12,31)

$holidays = Holidays.between(from, to, :ca, :us, :informal)
# $holidays = Holidays.between(from, to, :ca, :us)
# $holidays = Holidays.between(from, to, :us, :informal)
# $holidays = Holidays.between(from, to, :us)
# $holidays = Holidays.between(from, to, :ca, :informal)
# $holidays = Holidays.between(from, to, :ca)

# ap $holidays.map{|e| e[:name]}.sort.uniq

def find_a_holiday(a_string, how_close=0.9)
  looking_for = a_string.strip.downcase

  found_date = nil
  $holidays.each do |entry|
    if String::Similarity.cosine(entry[:name].downcase, looking_for) >= how_close
      found_date = entry[:date]
      break
    end
  end

  return found_date
end


def convert_to_date(a_string)
  return nil unless a_string.is_a?(String)  ||  a_string.empty?
  looking_for = a_string.strip.downcase
  return nil if looking_for.empty?

  found_date  = nil

  if looking_for =~ /\d/
    found_date = Chronic.parse(a_string, {context: :future, guess: true})
  else
    # holiday names contain no digits
    found_date = find_a_holiday(looking_for, 0.95)
  end

  return found_date&.to_date
end


puts
puts "Testing 'date.parse' at #{Time.now}"
puts


tests = []
header = ['input']

header << 'convert_to_date'
tests << -> (a_string){convert_to_date(a_string)}

# header << 'Date.parse'
# tests << -> (a_string){ Date.parse(a_string)}

# header << 'ActiveSupport#to_date'
# tests << -> (a_string){ a_string.to_date}

header << 'Chronic.parse'
tests << -> (a_string){
  result = Chronic.parse(a_string, {context: :future, guess: true})
  result.nil? ? nil : result.to_date
}

header << 'Named Holiday 0.95'
tests << -> (a_string){find_a_holiday(a_string, 0.95)}

header << 'Named Holiday 0.925'
tests << -> (a_string){find_a_holiday(a_string, 0.925)}

header << 'Named Holiday 0.90'
tests << -> (a_string){find_a_holiday(a_string, 0.90)}

header << 'Named Holiday 0.85'
tests << -> (a_string){find_a_holiday(a_string, 0.85)}

result = []

dates_closed.each do |a_string|
  next if a_string.strip.start_with?('#')

  entry = [a_string]

  tests.each do |test_it|
    begin
      d8      = test_it.call(a_string)
    rescue Exception => e
      d8      = "*** #{e} ***"
    end

    entry << d8.to_s
  end

  result << entry
end

puts TTY::Table.new(header,result).render(:ascii)
