#!/usr/bin/env ruby

require 'normalize_key'

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'csv'
require 'pathname'

require 'rover-df'

aapl_csv = Pathname.pwd + 'aapl.csv'

aapl_df = Rover.read_csv aapl_csv

debug_me{[
	"aapl_df.size",
	"aapl_df.keys",
	"aapl_df.methods"
]}

mapping = {}

keys = aapl_df.keys

keys.each do |key|
  new_key = NormalizeKey.new( key: key ).call
  mapping[key] = new_key
end

debug_me{[ mapping ]}

