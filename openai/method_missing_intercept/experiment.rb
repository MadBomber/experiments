#!/usr/bin/env ruby

require 'debug_me'
include DebugMe

require_relative "./calculator.rb"

calc = Calculator.new

calc.sub(5,3)

# Try calc.add(2,3)
# calc.add(2,3)
