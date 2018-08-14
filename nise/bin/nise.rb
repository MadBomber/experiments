#!/usr/bin/env ruby
# nise.rb

require_relative '../lib/nise'
require_relative '../lib/nise/cli.rb'

NISE::CLI.new(ARGV).run
