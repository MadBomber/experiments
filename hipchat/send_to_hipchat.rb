#!/usr/bin/env ruby -wKU
######################################################
###
##  File: send_to_hipchat.rb
##  Desc: send a message to a hipchat room
#

if ARGV.empty?  || ARGV.first.start_with?('-')
puts <<EOS

  Example of how to send a message to a hipchat room.  uses
  the system environment variables:
    HIPCHAT_ROOM  # the intended room for the message to be delivered
    HIPCHAT_TOKEN # the API token for the hipchat.com account

  Whatever you put on the command line will be sent as the message.

EOS
exit
end

message = ARGV.join(' ')


# Example using STDLIB components

require 'net/http'
require 'json'

room          = ENV['HIPCHAT_ROOM']   ||  'myroom'
token         = ENV['HIPCHAT_TOKEN']  ||  'xyzzy'
api_version   = ENV['HIPCHAT_API']    ||  'v2'

uri = URI.parse("https://api.hipchat.com/#{api_version}/room/#{room}/notification?auth_token=#{token}")

http = Net::HTTP.new(uri.host, uri.port)

http.use_ssl = true

request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})

request.body = {
    "notify"          => true,
    "message_format"  => "text",
    "message"         => "STDLIB -=> #{message}"
}.to_json

response = http.request(request)

puts response.body


# Example Using the Hipchat gem

require 'hipchat'

client = HipChat::Client.new(token, api_version: api_version)
# 'username' is the name for which the message will be presented as from
# 'username' looks like it is being ignored
client[room].send('', "gemified -=> #{message}")




