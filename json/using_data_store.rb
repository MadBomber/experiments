#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: using_data_store.rb
##  Desc: Steam JSON with OJ
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

TEMP_FILENAME = 'temp.json'

require_relative 'data_store'

require 'pathname'
require 'get_process_mem'

require 'amazing_print'

require 'debug_me'
include DebugMe


@mem_file = File.new('mem_size.txt', 'w')

@zero   = 'zero'
@one    = 'one'
@two    = 'two'
@three  = 'three'
@four   = 'four'
@five   = 'five'
@six    = 'six'
@seven  = 'seven'


######################################################
# Local methods

def record_memory_size
  mem_size = GetProcessMem.new.mb
  puts mem_size
  @mem_file.puts mem_size
end

record_memory_size



def add_entry(a_hash)
  @data << a_hash
end


def random_entry
  {
    @zero   => Time.now,
    @one    => rand(100),
    @two    => "multi-line\nstring",
    @three  => rand(100),
    @four   => sub_array(5)
  }
end

def random_hash
  {
    @five  => rand(100),
    @six   => rand(100),
    @seven => rand(100)
  }
end


def sub_array(array_size)
  array = []
  array_size.times do |x|
    array << random_hash
  end

  array
end

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


if ARGV.include?('--file')
  @data = ReportData::DataStore.new(TEMP_FILENAME)
else
  @data = ReportData::DataStore.new
end


entry_count = 0


debug_me{[ :@data ]}


1_000_000.times do |x|
  entry_count += 1

  record_memory_size if 0 == entry_count % 10_000

  add_entry(random_entry)
end



@data.each do |an_entry|
  entry_count +=1
  record_memory_size if 0 == entry_count % 10_000

  ap an_entry if 0 == entry_count % 100_000
end


print "\n@data.size => #{@data.size}\n\n"


# SMELL: what if it were an Array?
@data.close

