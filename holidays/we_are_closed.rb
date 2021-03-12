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

# require 'activesupport'
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
  12/31
  1/1
  2/29
  2/30
  easter
  thanksgiving
  4th friday in november
  christmas eve
  christmas day
  new year's eve
  new year's day

  12-31
  1-1
  2-29
  2-30
  easter
  thanksgiving
  4th friday in nov
  christmas
  new year's
  new years

  12 / 31
  1 / 1
  2 / 29
  2 / 30

  12 - 31
  1 - 1
  2 - 29
  2 - 30


  12 /31
  1 /1
  2 /29
  2 /30

  12 -31
  1 -1
  2 -29
  2 -30


  12/ 31
  1/ 1
  2/ 29
  2/ 30

  12- 31
  1- 1
  2- 29
  2- 30


  31/12
  1/1
  29/2
  30/2

  31-12
  1-1
  29-2
  30-2

    dec 31
    jan 1
    feb 29
    feb 30
    jun    3rd
    jul 4th
    dec 25th

    december 31
    january 1
    feburary 29
    feburary 30
    july 4th
    decimal 25th

  xyzzy
DATA


max_length = dates_closed.map{|v|v.size}.max + 4

puts
puts "Testing 'date.parse' at #{Time.now}"
puts


tests = []

tests << -> (a_string){ Date.parse(a_string)}

tests << -> (a_string){
  result = Chronic.parse(a_string, {context: :future, guess: true})
  result.nil? ? nil : result.to_date
}



result = []

header = ['input', 'Date.parse', 'Chronic.parse']

dates_closed.each do |a_string|

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
