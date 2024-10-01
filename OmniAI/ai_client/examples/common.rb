# experiments/OmniAI/examples/common.rb
#
# Stuff common to all the examples

require_relative '../ai_client'

require 'amazing_print'

require 'debug_me'
include DebugMe

def title(a_string='Something Different', chr='=')
  puts
  puts a_string
  puts chr*a_string.size
end


def box(a_string='Something Different', chr='=')
  a_string = "#{chr*2} #{a_string} #{chr*2}"  
  a_line = "\n" + (chr*a_string.size) + "\n"
  puts "#{a_line}#{a_string}#{a_line}"
  puts
end
