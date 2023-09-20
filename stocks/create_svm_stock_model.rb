#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: create_svm_stock_model.rb
##  Desc: Creat an SVM classification model for a Stock
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# require 'rumale-svm'

require 'sqa'     # v0.0.12
require 'sqa/cli'

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("Creat an SVM classification model for a Stock") do |o|

  o.path    '-c', '--config', 'Config file for SQA',  default: HOME + ".sqa.yml"
  o.int     '-w', '--window', 'forecast window',      default: 14
  o.array   '-t', '--tickers','ticker symbols',       default: %w[aapl f gm]
  o.array         '--deltas', 'delta points',         default: [1.0, 5.0]

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

abort_if_errors


######################################################
# Local methods



# Creates a libsvm formatted file for a given
# stock classified by future adjusted closing price
# window days into the future.
#
# stock   (SQA::Stock)
# window  (Integer) forecast window into the future
#
def create_libsvm_file(stock, window)
  filename  = stock.ticker + "_libsvm.txt"
  file      = File.open(filename, 'w')
  features  = format_features(stock, window)
  labels    = get_recommendations(stock.df.adj_close_price.to_a, window).map{|v| v.to_s + " "}
  (features.size).times do |x|
    file.puts labels[x] + features[x]
  end
end


def get_recommendations(prices, window, delta_array=[1.0, 5.0])
  last_inx = prices.size - window - 1
  labels   = []

  (0..last_inx).each do |x|
    labels << recommendation(prices[x], prices[x+window], delta_array)
  end

  labels
end


def format_features(stock, window)

end





######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

stocks = []

sqa_args  = "-c #{configatron.config}"
sqa_args += " --debug"    if debug?
sqa_args += " --verbose"  if verbose?

debug_me{[
  :sqa_args
]}

print "initializing SQA ... " if verbose?
SQA.init(sqa_args)
puts "done" if verbose?

ap SQA.config if debug?

configatron.tickers.each do |ticker|
  print "Loading #{ticker} ... " if verbose?
  stocks << SQA::Stock.new(ticker: ticker)
  puts "done" if verbose?
end

