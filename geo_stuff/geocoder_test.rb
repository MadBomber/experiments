#!/usr/bin/env ruby -wKU

require 'kick_the_tires'
include KickTheTires

require 'debug_me'
include DebugMe

#require 'redis'

require 'geocoder'

show Geocoder.configure( 
  #cache:        Redis.new,
  #cache_prefix: 'geocoder:',
  timeout:      5, 
  lookup:       :google,
  ip_lookup:    :freegeoip,
  language:     :en,
  units:        :mi,
  distances:    :linear
)

=begin
def set_defaults

  # geocoding options
  @data[:timeout]      = 3           # geocoding service timeout (secs)
  @data[:lookup]       = :google     # name of street address geocoding service (symbol)
  @data[:ip_lookup]    = :freegeoip  # name of IP address geocoding service (symbol)
  @data[:language]     = :en         # ISO-639 language code
  @data[:http_headers] = {}          # HTTP headers for lookup
  @data[:use_https]    = false       # use HTTPS for lookup requests? (if supported)
  @data[:http_proxy]   = nil         # HTTP proxy server (user:pass@host:port)
  @data[:https_proxy]  = nil         # HTTPS proxy server (user:pass@host:port)
  @data[:api_key]      = nil         # API key for geocoding service
  @data[:cache]        = nil         # cache object (must respond to #[], #[]=, and #keys)
  @data[:cache_prefix] = "geocoder:" # prefix (string) to use for all cache keys

  # exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and TimeoutError
  @data[:always_raise] = []

  # calculation options
  @data[:units]     = :mi      # :mi or :km
  @data[:distances] = :linear  # :linear or :spherical
end

=end



# Look up street addresses, IP addresses, and geographic coordinates
# "Eiffel Tower"      #=> 	48.8582, 2.2945
# 44.9817, -93.2783  #=> 	350 7th St N, Minneapolis, MN
# 24.193.83.1         #=> Brooklyn, NY, US


# ActiveRecord / Rails integration

=begin

# Perform geographic queries using objects

Hotel.near(”Vancouver, Canada”)
@event.nearbys
@restaurant.distance_to(”Eiffel Tower”)
@restaurant.bearing_to(”Eiffel Tower”)


# find geographic center of multiple places ActiveRecord Examples

Geocoder::Calculations.geographic_center(
  [
    @brooklyn_bridge,
    @chrysler_building,
    @madison_square_garden
  ]
)
=end

# Search for geographic information about a street address, IP address, or set of coordinates (Geocoder.search returns an array of Geocoder::Result objects):

show Geocoder.search("1 Twins Way, Minneapolis")
show Geocoder.search("44.981667,-93.27833")
show Geocoder.search("204.57.220.1")


__END__

Command Line Interface
Search Geocoding API

The command line interface works just like the Geocoder.search method and allows you to set various configuration options like geocoding service, language, etc. You can also get the raw JSON response (or URL) from the geocoding API:
$ geocode -s geocoder_ca "44.981667,-93.27833"
Latitude:        44.981165
Longitude:       -93.279225
Full address:    380 7th St N, Minneapolis, ...
City:            Minneapolis
State/province:  MN
Postal code:     55403
Country:         United States
Google map:      http://maps.google.com/maps?...

$ geocode --json "1 Twins Way, Minneapolis"
{
  "status": "OK",
  "results": [ {
    "types": [ "street_address" ],
    "formatted_address": "536 1/2 N 3rd St...",
    ...
  } ]
} 

