#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: geohash_it.rb
##  Desc: Reads a text file of USPS zipcodes w/ lat lng and geohashes each entry
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
#   GeoCoded postal codes are available from
#   http://download.geonames.org/export/zip/
#

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

require 'geohash'

configatron.version = '0.0.1'

HELP = <<EOHELP
Example:

  ./geohash_it.rb ./oklahoma_postal_codes_geocoded.txt

EOHELP

cli_helper("Reads a text file of USPS zipcodes w/ lat lng and geohashes each entry") do |o|

  # o.bool    '-b', '--bool',   'example boolean parameter',   default: false
  # o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  # o.int     '-i', '--int',    'example integer parameter',   default: 42
  # o.float   '-f', '--float',  'example float parameter',     default: 123.456
  # o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  # o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  # o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

configatron.input_files = get_pathnames_from( configatron.arguments, '.txt')

if configatron.input_files.empty?
  error 'No text files were provided'
end

abort_if_errors


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

field_names_to_columns_xref = {
    country:     0, # "US",
    zipcode:     1, # "99553",
    city:        2, # "Akutan",
    state:       3, # "Alaska",
    state_abbr:  4, # "AK",
    geoname:     5, # "Aleutians East",
    # xyzzy:     6, # "013",
    # xyzzy:     7, # "",
    # xyzzy:     8, # "",
    latitude:    9, # "54.143",
    longitude:  10, # "-165.7854",
    #xyzzy:     11, # "1"
}

zip_col = field_names_to_columns_xref[:zipcode]
lat_col = field_names_to_columns_xref[:latitude]
lng_col = field_names_to_columns_xref[:longitude]

city_col        = field_names_to_columns_xref[:city]
state_abbr_col  = field_names_to_columns_xref[:state_abbr]

configatron.input_files.first.readlines.each do |a_line|
  cols = a_line.split("\t")
  lat   = cols[lat_col].to_f
  long  = cols[lng_col].to_f

  geohash = GeoHash.encode(lat, long)

  puts "#{geohash} #{cols[city_col]}, #{cols[state_abbr_col]} #{cols[zip_col]}  (#{cols[lat_col]}, #{cols[lng_col]})"
end
