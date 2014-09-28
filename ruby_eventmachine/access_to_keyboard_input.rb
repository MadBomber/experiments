#!/bin/env ruby
require 'rubygems'
require 'eventmachine'

module MyKeyboardHandler
  def receive_data keystrokes
    ## only one keystroke at a time is return but not until
    ## after the return key is pressed.
    puts "I received the following data from the keyboard: #{keystrokes}"
  end
end

EM.run {
  EM.open_keyboard(MyKeyboardHandler)
}

