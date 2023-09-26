#!/usr/bin/env ruby
# experiments/api_key_rotater/rotate_api_keys.rb

# TODO: maybe it is sufficient to switch the
# 			api key after every RATE_CNT accesses
# 			regardless of the RATE_PER.  Or maybe
# 			switch on an X < RATE_CNT.


class RateLimitReached < StandardError; end

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'nenv'

# You have more than one official API_KEY.  Each
# key is rate limited to something like 5 accesses per
# minute.

debug_me{[
	"Nenv.api_keys", # this will be nil because the method does not exist
	"ENV['API_KEYS']"
]}

@api_keys = Nenv.api_keys ? Nenv.api_keys.split(',') : raise("No API keys")
@api_key  = @api_keys.first

RATE_CNT 	= Nenv.rate_cnt ? Nenv.rate_cnt.to_i :  5
RATE_PER 	= Nenv.rate_per ? Nenv.rate_per.to_i : 15

debug_me('== INIT =='){[
	"@api_keys",
	"@api_key",
	"RATE_CNT",
	"RATE_PER",
]}


def next_api_key
	@api_key 			= @api_keys.rotate!.first
	@access_time 	= Time.now.to_i
	debug_me("#{@api_key}")
end


def api_key
	@api_key.nil? ? next_api_key : @api_key
	debug_me("#{@api_key}")
end



def time_expired?
	old_time 		= @access_time
	now_time 		= Time.now.to_i
	delta_time 	= now_time - old_time

	result = delta_time < RATE_PER

	debug_me("#{result}:#{delta_time}")

	result
end


def reset_rate_limits
	debug_me("== RESET ==")
	@access_counter = RATE_CNT
	@access_time 		= Time.now.to_i
end


def access
	debug_me("FakeAccess: #{@access_counter}")

	@access_counter -= 1
		access_a_rate_limited_api

	if @access_counter <= 0
		if time_expired?
			reset_rate_limits
			raise RateLimitReached
		else
			reset_rate_limits
		end
	end
end


def access_a_rate_limited_api
	duration = rand(5)

	debug_me("= #{@api_key} ="){[
		"@access_counter",
		:duration,
		"@retry_count"
	]}

	sleep(duration)
end

#####################################################
## Main line

@retry_count 		= @api_keys.size
@access_counter = RATE_CNT

debug_me("RetryCount: #{@retry_count}")


@access_time = @access_time.nil? ? Time.now.to_i : @access_time

50.times do |x|

	begin
	  access
	rescue RateLimitReached => e
		debug_me("== RateLimitReached ==")
	  if @retry_count < 0
	  	debug_me("== RETRY < 0 ==")
	    raise RateLimitReached, "Consider slowing down or adding another key or spending money and buying better access rights."
	  else
	  	debug_me
	    @retry_count -= 1
	    next_api_key
	    retry
	  end
	end
end

