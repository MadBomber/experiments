#!/usr/bin/env ruby
##############################################
###
##  File: test_bunny_farm.rb
##  Desc: Lets plant some bunnies
#

require 'debug_me'
include DebugMe

require 'awesome_print'
require 'require_all'

require 'bunny_farm'

require_all 'messages/*.rb'

BunnyFarm.config do
 config_dir   File.dirname(__FILE__)+'/config'
 bunny_file   'rabbitmq.yml.erb'
 block        true
end

ap BunnyFarm::CONFIG

BunnyFarm.manage

