# ~/lib/ruby/api_key_manager.rb
#
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: api_key_manager.rb
##  Desc: Manage multiple API keys based upon rate count limitation.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
#
# Some APIs offer a free api_key with a rate limits which are too low for
# normal software development.  If you have several of these free rate limited
# keys you may be able to rotate the key usage during development.  Once your
# product reachs productions, you should ditch the free api keys are purchase
# a production key that has the appropriate charastics your product needs.

# Simple key manager that rotates keys based upon a consecutive usage counter.
module ApiKeyManager
  class Counter

  	# api_keys (Array of String) or CSV String
  	# 	of rate limited API Keys.
  	#
  	# rate_count (Integer) or String convertable to Integer
  	# 	number of times to use an API Key before
  	# 	changing to a new one.
  	#
    def initialize(api_keys, rate_count=5)
      @api_keys 			= api_keys.is_a?(String) 		? api_keys.split(',') : api_keys
      @rate_count 		= rate_count.is_a?(Strubg) 	? rate_count.to_i 		: rate_count
      @counter 				= @rate_count # NOTE: it is a count down counter
      @current_index 	= 0
    end


    def reset_counter
      @counter  = @rate_count
    end


    # Use the same API key @rate_count times
    # When @rate_count is exceeded, switch to a new
    # api_key.
    #
    def api_key
      if @counter < 1
        @current_index 	= (@current_index + 1) % @api_keys.length
        reset_counter
      end

      @counter -= 1
      @api_keys[@current_index]
    end
  end # class Counter


  ########################################################
  # Dealing with a limitation in the API keys of a maximum
  # number of accesses per a specific period of time - usually
  # expressed as a count per X seconds.  Example: 5/60
  #
  # When the count has been used within the specified period of time,
  # then it is time to use a new API key.
  #
  class Rate

    # api_keys (Array of String) or CSV String
    #   of rate limited API Keys.
    #
    # rate_count (Integer) or String convertable to Integer
    #   number of times to use an API Key before
    #   changing to a new one.
    #
    # rate_period (Integer) or String convertable to Integer
    #   number of seconds to use an API Key before
    #   changing to a new one.
    #
    def initialize(api_keys, rate_count=5, rate_period=60)

      debug_me{[
        :api_keys,
        :rate_count,
        :rate_period
      ]}

      @api_keys       = api_keys.is_a?(String)  ? api_keys.split(',') : api_keys

      @rate_count     = rate_count.is_a?(String)  ? rate_count.to_i   : rate_count
      @rate_period    = rate_period.is_a?(String) ? rate_period.to_i  : rate_period

      reset_timer
      reset_counter

      @current_index  = 0
    end


    def reset_counter
      debug_me("== reset counter ==")
      @counter  = @rate_count
    end


    def reset_timer
      debug_me("== reset timer ==")
      @start_timer  = Time.now.to_i
      @end_timer    = @start_timer + @rate_period
    end


    #
    def api_key
      now = Time.now.to_i

      debug_me{[
        :now,
        "@end_timet",
        "now <= @end_timer",
        "@counter",
        "@counter < 1"
      ]}

      # Have we already used up our access count for this period?
      if now <= @end_timer && @counter < 1
        debug_me "one"
        @current_index  = (@current_index + 1) % @api_keys.length
        reset_timer
        reset_counter
      elsif now > @end_timer
        debug_me "two"
        # Continue using same api key
        reset_timer
        reset_counter
      end

      # SNELL: Can counter go negative?  If so, do we care?

      @counter -= 1
      @api_keys[@current_index]
    end
  end # class Rate
end # module ApiKeyManager
