#!/usr/bin/env ruby

require 'dnssd'
require 'pp'

DNSSD.browse '_IsePrincess._tcp.' do |r|
	pp r
	puts "-"*15
end

