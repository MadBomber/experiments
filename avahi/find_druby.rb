#!/usr/bin/env ruby

require 'rubygems'
require 'systemu'
require 'pp'
require 'awesome_print'

# a,b,c = systemu "avahi-browse -r -t -f -a -p | fgrep 'druby'"
a,b,c = systemu "avahi-browse -r -t -f -p _druby._tcp | grep ^="


services = b.split("\n").map {|s| s.split(';')}

ap services


