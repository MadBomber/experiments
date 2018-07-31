#!/usr/bin/env ruby
# test.rb
# a proof of concept

require 'debug_me'
include DebugMe

require_relative 'inline'

def hello_world
  Inline::Crystal.new(
    # a metadata Hash that describes the arguments
    # and the class of the returned value
    source: # either a File object or a string
      <<~CRYSTAL
        puts "Hello World"
      CRYSTAL
  )
end # def hello_world

hello_world
hello_world
