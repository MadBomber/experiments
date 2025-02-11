#############################################
###
##	File:	test_geokit.rb
##	Desc:	do some testing
#

# FIXME: Ruby v2+ not working the require is failing on OpenSSL-related problem
require 'geokit'

# These defaults are used in Geokit::Mappable.distance_to and in acts_as_mappable
Geokit::default_units = :miles
Geokit::default_formula = :sphere

# This is the timeout value in seconds to be used for calls to the geocoder web
# services.  For no timeout at all, comment out the setting.  The timeout unit
# is in seconds.
Geokit::Geocoders::timeout = 3

# These settings are used if web service calls must be routed through a proxy.
# These setting can be nil if not needed, otherwise, addr and port must be
# filled in at a minimum.  If the proxy requires authentication, the username
# and password can be provided as well.
Geokit::Geocoders::proxy_addr = nil
Geokit::Geocoders::proxy_port = nil
Geokit::Geocoders::proxy_user = nil
Geokit::Geocoders::proxy_pass = nil

# This is your yahoo application key for the Yahoo Geocoder.
# See http://developer.yahoo.com/faq/index.html#appid
# and http://developer.yahoo.com/maps/rest/V1/geocode.html
Geokit::Geocoders::yahoo = 'REPLACE_WITH_YOUR_YAHOO_KEY'

# This is your Google Maps geocoder key.
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
Geokit::Geocoders::google = 'REPLACE_WITH_YOUR_GOOGLE_KEY'

# This is your username and password for geocoder.us.
# To use the free service, the value can be set to nil or false.  For
# usage tied to an account, the value should be set to username:password.
# See http://geocoder.us
# and http://geocoder.us/user/signup
Geokit::Geocoders::geocoder_us = false

# This is your authorization key for geocoder.ca.
# To use the free service, the value can be set to nil or false.  For
# usage tied to an account, set the value to the key obtained from
# Geocoder.ca.
# See http://geocoder.ca
# and http://geocoder.ca/?register=1
Geokit::Geocoders::geocoder_ca = false

# This is the order in which the geocoders are called in a failover scenario
# If you only want to use a single geocoder, put a single symbol in the array.
# Valid symbols are :google, :yahoo, :us, and :ca.
# Be aware that there are Terms of Use restrictions on how you can use the
# various geocoders.  Make sure you read up on relevant Terms of Use for each
# geocoder you are going to use.
Geokit::Geocoders::provider_order = [:google,:us]

#########################################################

a=Geokit::Geocoders::YahooGeocoder.geocode '2907 North Mira Lagos, Grand Prairie, TX'
puts a.ll
puts "# => 37.79363,-122.396116"
b=Geokit::Geocoders::YahooGeocoder.geocode '101 East Lee Blvd, Lawton, OK'
puts b.ll
puts "# => 37.786217,-122.41619"
puts a.distance_to(b)
puts "# => 1.21120007413626"
puts a.heading_to(b)
puts "#=> 244.959832435678"
c=a.midpoint_to(b)      # what's halfway from a to b?
puts c.ll
puts "#=> 37.7899239257175,-122.406153503469"
d=c.endpoint(90,10)     # what's 10 miles to the east of c?
puts d.ll
puts "#=> 37.7897825005142,-122.223214776155"
