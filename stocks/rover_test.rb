#!/usr/bin/env ruby

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'csv'

require 'rover-df'

aapl_csv = Pathname.pwd + 'aapl.csv'

aapl_df = Rover.read_csv aapl_csv

debug_me{[
	"aapl_df.size",
	"aapl_df.keys",
	"aapl_df.methods"
]}

