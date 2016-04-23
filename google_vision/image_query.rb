#!/usr/bin/env ruby
############################################################
###
##  File: image_query.rb
##  Desc: Query a set of image metadata JSON files for stuff.
##
#

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'json'
require 'jsonpath'

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Query json for security, location or both

  Security and location are expresed in their hashed form

EOHELP

cli_helper("Resize image(s) to a standard size/geometry") do |o|

  o.int     '-s', '--security',   'Security (hash)',  default:  0  # security hash
  o.string  '-l', '--location',   'Location (hash)',  default:  'xyzzy'  # location hash
  o.string  '-o', '--observation','observation (keyword)', default: ''
  o.bool    '-c', '--count',      'Report only the image counts that match', default: false

end


# Display the usage info
if  ARGV.empty?   ||  ARGV.include?('-h')  ||  ARGV.include?('--help')
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

configatron.security = nil if configatron.security == 0
configatron.location = nil if configatron.location == 'xyzzy'

VALID_SECURITY_HASH = [1,2,4,8,16]

if configatron.security.nil?  &&  configatron.location.nil?
  error "Security, location or both are required; otherwise what's the point of the query?"
end

unless configatron.security.nil?
  unless VALID_SECURITY_HASH.include? configatron.security
    error "Invalid security hash #{configatron.security}; must be one of #{VALID_SECURITY_HASH.join(', ')}"
  end
end


configatron.input_files = get_pathnames_from( configatron.arguments, 
  ['.json'])

if configatron.input_files.empty?
  error 'No image metadata JSON files were provided'
end

abort_if_errors






######################################################
# Local methods

class Array
  def deep_include?(a_string)
    result = false
    self.each do |s|
      if s.include?(a_string)
        result = true
        break
      end
    end
    return result
  end # def deep_include?(a_string)
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


ap configatron.to_h  if debug?


counts = {
  total:        0,
  security:     0,
  location:     0,
  observation:  0,
  selected:     0
}

selected_images = []

configatron.input_files.each do |json_file_path|

  counts[:total] += 1

  metadata = JSON.parse json_file_path.read

  puts "Reviewing #{metadata['file_name'].split('/').last} ..." if verbose?

  if debug?
    puts 
    puts metadata["file_name"]
    ap metadata["security"]
    ap metadata["location"]
    puts
  end

  unless configatron.security.nil?
    next if metadata.dig('security','value') > configatron.security
    counts[:security] += 1
  end

  unless configatron.location.nil?
    next unless metadata.dig('location','geohash').start_with? configatron.location
    counts[:location] += 1
  end

  unless configatron.observation.empty?
    observations = JsonPath.on(metadata, '$..description')
    next unless observations.deep_include?( configatron.observation )
    counts[:observation] += 1
  end

  if debug?
    puts "\n\n"
    puts "#"*64
    ap metadata
  end

  selected_images << metadata

  counts[:selected] += 1


end # configatron.input_files.each do |json_file_path|

puts "\n\nQuery Parameters"
puts "----------------"

puts "  Sevurity level hash:   #{ configatron.security }" unless configatron.security.nil?
puts "  Nearby location hash:  #{ configatron.location }" unless configatron.location.nil?
puts "  Observation keyword:   #{ configatron.observation }" unless configatron.observation.empty?


puts "\n\nCounts"

ap counts

if count?
  exit
end


puts "\n\nQuery Results"
puts "-------------"

selected_images.each do |metadata|
  puts "\n\n"
  puts "#"*64
  puts "Image file path: " + metadata['file_name']
  print  "      Security: " + metadata.dig('security', 'marking')
  print " (#{metadata.dig('security', 'value')})"
  puts " -- " + metadata.dig('security', 'long_marking')
  print "      Location: " + metadata.dig('location', 'geohash')
  print " Latitude: #{metadata.dig('location', 'latitude')}"
  puts  " Longitude: #{metadata.dig('location', 'longitude')}"

  puts "\n\nObservations"
  puts "------------"

  unless metadata['labelAnnotations'].nil?
    metadata['labelAnnotations'].each do |observation|
      printf "  %20s %f \n", observation['description'], observation['score']
    end # metadata['labelAnnotations'].each do |observation|
  else
    puts "No observables have been recorded for this image."
  end

end # selected_images.each do |metadata|

puts "\n\n"

