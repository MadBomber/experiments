#!/usr/bin/env ruby
# experiments/api_key_rotater/rotate_api_keys.rb

# TODO: maybe it is sufficient to switch the
# 			api key after every RATE_CNT accesses
# 			regardless of the RATE_PER.  Or maybe
# 			switch on an X < RATE_CNT.

# NOTE: This experiment is over.  It was turned into the
# 			gem api_key_manager with a RateLimited class



class RateLimitReached < StandardError; end

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'nenv'

require_relative './api_key_manager'

# You have more than one official API_KEY.  Each
# key is rate limited to something like 5 accesses per
# minute.

debug_me{[
	"Nenv.api_keys", # this will be nil because the method does not exist
	"ENV['API_KEYS']"
]}

@mgr = ApiKeyManager::Rate.new(
				ENV['API_KEYS'],
				ENV['RATE_CNT'],
				ENV['RATE_PER']
			)

debug_me('== INIT =='){[
	'@mgr'
]}



def access_a_rate_limited_api
	duration 	= rand(5)
	api_key 	= @mgr.api_key

	debug_me("= #{api_key} for #{duration} =")

	sleep(duration)
end

#####################################################
## Main line

50.times do |x|
	access_a_rate_limited_api
end

