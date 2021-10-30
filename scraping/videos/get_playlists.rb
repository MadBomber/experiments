#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: get_all_playlists.rb
##  Desc: Retrieve all playlists from a channel
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'pathname'

require 'json'

APPLICATION_NAME = 'YouTube Data API Ruby Tests'

API_KEY     = ENV.fetch('YOUTUBE_PUBLIC_DATA_API_V3', 'this key is restriced to IP and API')
CHANNEL_ID = ENV.fetch('CHANNEL_ID', 'home urlthe ID for the channel')

######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

here                = Pathname.pwd
playlists_filename  = 'playlists.json'
playlists_filepath  = here + playlists_filename

curl_command  =  "curl "
curl_command  += "'https://youtube.googleapis.com/youtube/v3/playlists?"
curl_command  += "channelId=#{CHANNEL_ID}&"
curl_command  += "part=snippet&"
curl_command  += "key=#{API_KEY}' "
curl_command  += "--header 'Accept: application/json'"

json_string = `#{curl_command}`

playlists_filepath.write json_string

__END__

playlist_hash = JSON.parse json_string

ap playlist_hash
