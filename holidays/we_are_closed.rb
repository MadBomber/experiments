#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: we_are_closed.rb
##  Desc: Playing with Holidays and Chronic gems
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



def normalize_holiday_name(a_string)
  return nil unless a_string.is_a?(String)
  a_string.strip.squeeze(' ').downcase.gsub("'",'')
end


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

    february 28
    february 29
    february 30

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

  first monday  in november
  second tuesday  in november
  third wednesday  in november
  fourth thursday  in november
  fifth friday  in november
  sixth friday  in november

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
  canada

  independance day
  independence day
  independence

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

  Martin Luther King, Jr. Day
  Martin Luther King Jr Day
  MLK Junior Day
  MLK Day
  MLK
  Martin Luther
  Martin Luther King
  MLK, JR day

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
  xyzzy eve
  xyzzy eve eve

  # multiple on one line

  12-31 1-1
  12-31 1-1 2-14
  12-31 1-1 2-14 4-25
  12-31 1-1 2-14 4-25 5/16
  12-31 1-1 2-14 4-25 5/16 6-3
  12-31 1-1 2-14 4-25 5/16 6-3 10/17
  12-31 1-1 2-14 4-25 5/16 6-3 10/17 4th of july, christmas

  4th of july; thanksgiven; christmas

  december 24, december 25, december 31, jan 1st

DATA

year  = Date.today.year

from  = Date.civil(year,1,1)
to    = Date.civil(year+1,12,31)

$holidays = Holidays.between(from, to, :ca, :us, :informal)
# $holidays = Holidays.between(from, to, :ca, :us)
# $holidays = Holidays.between(from, to, :us, :informal)
# $holidays = Holidays.between(from, to, :us)
# $holidays = Holidays.between(from, to, :ca, :informal)
# $holidays = Holidays.between(from, to, :ca)

$holidays.each do |entry|
  entry[:name] = normalize_holiday_name( entry[:name] )
end

$holiday_names = $holidays.map{|e| e[:name]}.sort.uniq


def best_match(a_string)
  return nil if a_string =~ /\d/

  looking_for   = normalize_holiday_name(a_string)
  max_value     = 0.89
  matching_name = nil

  $holiday_names.each do |try_this|
    value = String::Similarity.cosine(try_this.gsub("'",''), looking_for)

    if value > max_value
      max_value     = value
      matching_name = try_this
    end
  end

  unless matching_name.nil?
    matching_name += " (#{max_value})"
  end

  return matching_name
end


def holiday_name_on_date(a_date)
  return nil unless a_date.is_a?(Date)
  holiday_name = 'Closed'

  holidays = Holidays.on(a_date, :ca, :us, :informal)

  unless holidays.empty?
    result = holidays.map{|e| e[:name]}.uniq
    holiday_name = result.join('; ')
  end

  return holiday_name
end


# ap $holidays.map{|e| e[:name]}.sort.uniq


def find_a_holiday(a_string, how_close=0.9)
  temp        = best_match(a_string)
  return nil if temp.nil?

  lp_inx      = temp.index(' (') - 1
  looking_for = temp[0..lp_inx]

  holiday = $holidays.select {|e| e[:name] == looking_for}

  return holiday.empty? ? nil : holiday[0][:date]
end



def transform_holiday_name(a_string)
  given_this  = normalize_holiday_name(a_string)

  return_this = if given_this.include?('feburary')
                  given_this.gsub('feburary', 'february')
                elsif 'new years' == given_this
                  'new years day'
                elsif 'easter' == given_this
                  'easter sunday'
                elsif 'christmas' == given_this
                  'christmas day'
                elsif 'thanksgiving day' == given_this
                  'thanksgiving'
                elsif given_this.end_with?(' eve')
                  real_holiday_name = given_this.gsub(' eve', ' day')
                  real_holiday_date = convert_to_date(real_holiday_name)
                  if real_holiday_date.is_a?(Date)
                    return (real_holiday_date - 1.day)
                  else
                    return '*** EVE Conversion Error ***'
                  end
                elsif given_this.start_with?('mlk')
                  given_this.gsub('mlk','martin luther king')
                elsif given_this.split().any?{|part| %w[first second third forth fourth fifth sixth].include?(part)}
                  given_this
                    .gsub('first', '1st')
                    .gsub('second','2nd')
                    .gsub('third', '3rd')
                    .gsub('forth', '4th')
                    .gsub('fourth', '4th')
                    .gsub('fifth', '5th')
                    .gsub('sixth', '6th')
                else
                  given_this
                end

  return return_this
end


def convert_to_date(a_string)
  return nil unless a_string.is_a?(String)  ||  a_string.empty?
  looking_for = transform_holiday_name(a_string)
  return looking_for if looking_for.is_a?(Date)

  return nil if looking_for.empty?

  found_date  = nil

  if looking_for =~ /\d/
    found_date = Chronic.parse(looking_for, {context: :future, guess: true})
  else
    # holiday names contain no digits
    found_date = find_a_holiday(looking_for, 0.95)
  end

  return found_date&.to_date
end



tests = []
header = ['input']

header << 'convert_to_date'
tests << -> (a_string){convert_to_date(a_string)}

header << 'Holiday Name on Date'
tests << -> (a_string){holiday_name_on_date(convert_to_date(a_string))}

# header << 'Best Match'
# tests << -> (a_string){best_match(a_string)}

# header << 'Date.parse'
# tests << -> (a_string){ Date.parse(a_string)}

# header << 'ActiveSupport#to_date'
# tests << -> (a_string){ a_string.to_date}

# header << 'Chronic.parse'
# tests << -> (a_string){
#   result = Chronic.parse(a_string, {context: :future, guess: true})
#   result.nil? ? nil : result.to_date
# }

# header << 'Named Holiday 0.95'
# tests << -> (a_string){find_a_holiday(a_string.strip.downcase, 0.95)}

# header << 'Named Holiday 0.925'
# tests << -> (a_string){find_a_holiday(a_string.strip.downcase, 0.925)}

# header << 'Named Holiday 0.90'
# tests << -> (a_string){find_a_holiday(a_string.strip.downcase, 0.90)}

# header << 'Named Holiday 0.85'
# tests << -> (a_string){find_a_holiday(a_string.strip.downcase, 0.85)}

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


puts
puts "Testing parsing of date references at #{Time.now}"
puts
puts TTY::Table.new(header,result).render(:ascii)
puts
puts "Get Holiday Name on a Specific Date"
puts


__END__

dates = %w[ 1-1 2-14 4-25 5-16 6-3 7-4 10-17 12-25 ].map{|d8| Chronic.parse(d8).to_date}

dates.each do |a_date|
  puts "#{a_date} is #{holiday_name_on_date(a_date)}"
end
