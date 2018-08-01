#!/usr/bin/env ruby
# test.rb
# a proof of concept

require 'debug_me'
include DebugMe

require_relative 'inline/go'

def hello_world
  Inline::Go.new(
    # a metadata Hash that describes the arguments
    # and the class of the returned value
    source: # either a File object or a string
      <<~GO
        puts "Hello World"
      GO
  )
end # def hello_world

hello_world
hello_world
