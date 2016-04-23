#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: gv_observation_extraction_test.rb
##  Desc: Extract some observations from a photo using Google Vision
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'json'
require 'rmagick'
require 'google_cloud_vision'
require 'geohash36'

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

icon_dir    = my_dir   + 'icons'
symbol_dir  = icon_dir + 'symbols'



configatron.version     = '0.0.1'

configatron.extract
configatron.max_results

cli_helper("Extract some observations from a photo using Google Vision") do |o|

  o.string  '-x', '--extract',      'What to extract',        default: 'LABEL_DETECTION'
  o.int     '-m', '--max-results',  'maximum results/image',  default: 10

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

configatron.extract.upcase!

valid_extract = %w[ TEXT_DETECTION LABEL_DETECTION ]

unless valid_extract.include? configatron.extract
  error "Invalid extract thing: #{configatron.extract} should be one of: #{valid_extract.join(', ')}"
end

valid_max_range = (1..20)

unless valid_max_range.include? configatron.max_results
  error "Invalid max-results: #{configatron.max_results} should be in the range: #{valid_max_range}"
end

configatron.input_files = get_pathnames_from( configatron.arguments, 
  ['.jpg', '.png', '.gif'])

if configatron.input_files.empty?
  error 'No image files were provided'
end

abort_if_errors



######################################################
# Local methods

IMG_SERIAL_REGEX  = /_(.*)_/
AREA51_IMG_SERIAL = '0051'

def area51?(a_path)
  return (AREA51_IMG_SERIAL == IMG_SERIAL_REGEX.match(a_path.basename.to_s).captures.first)
end



TARGET_ICON       = symbol_dir + 'target.png'
AREA51_LOCATION   = [37.242, -115.8191]         # Lat, Long
DELTA             = [15, 15]



SECURITY = {
  1 => {
    marking:      'U',
    icon:         icon_dir + 'u.png',
    long_marking: 'Unclassified',
    value:        1 # 2**0
  },
  2 => {
    marking:      'C',
    icon:         icon_dir + 'c.png',
    long_marking: 'Confidential',
    value:        2 # 2**1
  },
  4 => {
    marking:      'S',
    icon:         icon_dir + 's.png',
    long_marking: 'Secret',
    value:        4 # 2**2
  },
  8 => {
    marking:      'TS',
    icon:         icon_dir + 'ts.png',
    long_marking: 'Top Secret',
    value:        8 # 2**3
  },
  16 => {
    marking:      'TS/SCI',
    icon:         icon_dir + 'ats.png',
    long_marking: 'Top Secret / Sensitive Compartmented Information',
    value:        16 # 2**4
  }
}

SECURITY_HASH = SECURITY.keys
CODE_WORDS    = [
  "Magic Carpet",
  "Desert Storm",
  "Bayonet Lightning",
  "Valiant Guardian",
  "Urgent Fury",
  "Eagle Claw",
  "Crescent Wind",
  "Spartan Scorpion",
  "Overlord",
  "Rolling Thunder"
]

def get_random_security
  level = SECURITY_HASH[ rand(SECURITY.size) ]
  security = SECURITY[ level ]
  if level == SECURITY_HASH.last
    security[:code_word] = CODE_WORDS.sample
  end
  return  security
end


def get_random_location( fixed_point=AREA51_LOCATION, delta=DELTA )
  offset  = []
  dir     = rand(2) == 0 ? -1.0 : 1.0
  offset << dir * rand(delta.first).to_f  / 10.0
  dir     = rand(2) == 0 ? -1.0 : 1.0
  offset << dir * rand(delta.last).to_f / 10.0
  point   = fixed_point.each_with_index.map {|v, x| v + offset[x]}
  coordinates = { latitude: point.first, longitude: point.last }
  coordinates[:geohash] = Geohash36.to_geohash( coordinates )
  return coordinates
end



######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if debug?



configatron.input_files.each do |image|

  print "Processing image #{image.basename} ... " if verbose?



  unless debug?
    response = GoogleCloudVision::Classifier.new( ENV['GOOGLE_VISION_API_KEY'],
      [
        { image: image, detection: configatron.extract, max_results: configatron.max_results }
      ]).response['responses'].first
  else
    response = {mode: "debug"}
  end


  response["file_name"]         = image.realpath

  if area51?(image)
    response[:security]             = SECURITY[16] # TS/SCI
    response[:security][:code_word] = "MAJESTIC"
    response[:security][:icon]      = TARGET_ICON
    coordinates                     = { latitude: AREA51_LOCATION.first, longitude: AREA51_LOCATION.last}
    coordinates[:geohash]           = Geohash36.to_geohash( coordinates )
    response[:location]             = coordinates
  else
    response[:security]             = get_random_security
    response[:location]             = get_random_location
  end

  ap response if debug?


  json_file_name = image.to_s.gsub(image.extname, '.json')

  json_file = File.new(json_file_name, 'w')

  json_file.puts response.to_json
  json_file.close

  puts "done." if verbose?

end


__END__




