#!/bin/env ruby
require 'rubygems'

# $eventmachine_library = :pure_ruby  ## If c++ version is available it will be the default

require 'eventmachine'

puts "EM.library_type: #{EM.library_type}"

module MyKeyboardHandler
  include EM::Protocols::LineText2
  def receive_line data
    puts "I received the following line from the keyboard: #{data}"
  end
end

EM.run {
  EM.open_keyboard(MyKeyboardHandler)
}

