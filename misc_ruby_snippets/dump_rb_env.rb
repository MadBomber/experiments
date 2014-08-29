#!/usr/bin/env ruby
############################################################
###
##	File:	dump_rb_env.rb
##	Desc:	ruby operation environment
#

require 'rbconfig'
include Config
require 'pp'

puts "=" * 20
pp CONFIG
puts "=" * 20
pp ENV
