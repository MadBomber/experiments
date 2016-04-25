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

  o.int     '-s', '--security',   'Security (hash)',                          default:  0       # security hash
  o.string  '-l', '--location',   'Location (hash)',                          default:  'xyzzy' # location hash
  o.string  '-o', '--observation','observation (keyword)',                    default:  ''
  o.bool    '-c', '--count',      'Report only the image counts that match',  default:  false
  o.path    '-k', '--kml',        'Generate KML to file',                     default:  Pathname.pwd

end


def kml?
  return (configatron.kml != Pathname.pwd)
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


SECURITY_ICONS_FOR_KML = <<EOS
  <!-- Unclassified -->
  <Style id="U">
    <IconStyle>
      <Icon>
        <href>http://www.earthpoint.us/Dots/GoogleEarth/pal5/icon20.png</href>
        <scale>1.0</scale>
      </Icon>
    </IconStyle>
  </Style>
  <!-- Confidential -->
  <Style id="C">
    <IconStyle>
      <Icon>
        <href>http://www.earthpoint.us/Dots/GoogleEarth/pal5/icon58.png</href>
        <scale>1.0</scale>
      </Icon>
    </IconStyle>
  </Style>
  <!-- Secret -->
  <Style id="S">
    <IconStyle>
      <Icon>
        <href>http://www.earthpoint.us/Dots/GoogleEarth/pal5/icon18.png</href>
        <scale>1.0</scale>
      </Icon>
    </IconStyle>
  </Style>
  <!-- Top Secret -->
  <Style id="TS">
    <IconStyle>
      <Icon>
        <href>http://www.earthpoint.us/Dots/GoogleEarth/pal5/icon19.png</href>
        <scale>1.0</scale>
      </Icon>
    </IconStyle>
  </Style>
  <!-- TS/SCI -->
  <Style id="TS/SCI">
    <IconStyle>
      <Icon>
        <href>http://www.earthpoint.us/Dots/GoogleEarth/pal5/icon56.png</href>
        <scale>1.0</scale>
      </Icon>
    </IconStyle>
  </Style>
EOS

def observations_report(a_hash)
  report = "Observation\n"
  report += "------------\n"

  unless a_hash['labelAnnotations'].nil?
    a_hash['labelAnnotations'].each do |observation|
      report += sprintf "  %20s %f \n", observation['description'], observation['score']
    end # metadata['labelAnnotations'].each do |observation|
  else
    report += "No observables have been recorded for this image.\n"
  end
  return report
end # def observations_report(a_hash)


def query_report
  report  = "Query Parameters\n"
  report += "----------------\n\n"

  report += sprintf("%s\n", "  Sevurity level hash:   #{ configatron.security}")    unless configatron.security.nil?
  report += sprintf("%s\n", "  Nearby location hash:  #{ configatron.location}")    unless configatron.location.nil?
  report += sprintf("%s\n", "  Observation keyword:   #{ configatron.observation}") unless configatron.observation.empty?

  return report
end

def write_placemark_point(file_pointer, a_hash)
  file_pointer.puts "  <Placemark>"
  file_pointer.puts "    <name>#{a_hash['file_name'].split('/').last}</name>"
  file_pointer.puts "    <description><![CDATA["
  file_pointer.print "      Security: (#{a_hash.dig('security','marking')}) -- "
  file_pointer.print "#{a_hash.dig('security','long_marking')}"

  if 16 == a_hash.dig('security','value')  # TS/SCI
    file_pointer.puts "  Codeword: #{a_hash.dig('security','code_word')}"
  else
    file_pointer.puts
  end

  file_pointer.puts "<br/>" + query_report.gsub("\n", "<br/>\n")

  file_pointer.puts "     <br/>"
  file_pointer.puts "     <img src='#{a_hash['file_name']}'><br/><br/>"

  file_pointer.puts observations_report(a_hash).gsub("\n", "<br>\n")

  file_pointer.puts "    ]]></description>"

  file_pointer.puts "    <styleUrl>##{a_hash.dig('security','marking')}</styleUrl>"

  file_pointer.puts "    <Point>"
  file_pointer.puts "      <coordinates>#{a_hash.dig('location','longitude')},#{a_hash.dig('location','latitude')},0</coordinates>"
  file_pointer.puts "    </Point>"
  file_pointer.puts "  </Placemark>"
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


puts "\n\n" + query_report


puts "\n\nCounts"

ap counts

unless count?

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

    puts "\n\n" + observations_report(metadata)

  end # selected_images.each do |metadata|

  puts "\n\n"

end # unless count?




if kml?
  print "\n\nGenerating KML file: #{configatron.kml} ... " if verbose?
  kml_file = File.new( configatron.kml, 'w' )

  # Simple KML header
  kml_file.puts '<?xml version="1.0" encoding="UTF-8"?>'
  kml_file.puts '<kml xmlns="http://www.opengis.net/kml/2.2">'
  kml_file.puts '<Document>'
  kml_file.puts "<Name>#{configatron.kml}</Name>"

  kml_file.puts SECURITY_ICONS_FOR_KML

  selected_images.each do |metadata|
    write_placemark_point(kml_file, metadata)
  end

  # Simple KML footer
  kml_file.puts '</Document>'
  kml_file.puts '</kml>'

  kml_file.close
  puts "done."  if verbose?
end

puts "\n\n" if verbose?

__END__




