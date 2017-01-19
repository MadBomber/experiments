#!/usr/bin/env ruby
######################################################
###
##  File: send_to_hipchat.rb
##  Desc: send a message to a hipchat room using v2 API
#
# Example Using the Hipchat gem

if ARGV.empty?  || ARGV.first.start_with?('-')
  puts <<~EOS

    Example of how to send a message to a hipchat room.  uses
    the system environment variables:
      HIPCHAT_ROOM    # the intended room for the message to be delivered
      HIPCHAT_TOKEN   # the API token for the hipchat.com account
      HIPCHAT_SERVER  # The customer server domain; defaults to the standard hipchat server
      HIPCHAT_USER    # Name to be displayed as the sender. Must be <= 20 characters

    Whatever you put on the command line will be sent as the message.

  EOS
  exit
end

message = ARGV.join(' ')

hc_room   = ENV['HIPCHAT_ROOM']
hc_server = ENV['HIPCHAT_SERVER']
hc_token  = ENV['HIPCHAT_TOKEN']

unless hc_room && hc_token
  puts <<~EOS

    The following system environment variables are required:

      HIPCHAT_ROOM .... current value: #{ENV['HIPCHAT_ROOM']}
      HIPCHAT_TOKEN ... current value: #{ENV['HIPCHAT_TOKEN']}

    The following system environment variables are optional:

      HIPCHAT_SERVER .. current value: #{ENV['HIPCHAT_SERVER']}
      HIPCHAT_USER .... current value: #{ENV['HIPCHAT_USER']}

  EOS
  exit
end


require 'hipchat'


name_of_sender    = ENV['HIPCHAT_USER'] || 'Billy Bob' # must be less than 20 chacters

if name_of_sender.size > 20
  name_of_sender = name_of_sender[0,20]
  puts <<~EOS

    WARNING: The HIPCHAT_USER value exceeded 20 characters limit - it was truncated.
             Value was: '#{ENV['HIPCHAT_USER']}'
             Value is:  '#{name_of_sender}'

  EOS
end


if hc_server.nil? || hc_server.empty?
  client = HipChat::Client.new(api_token, :api_version => 'v2') # use the default server
else
  client = HipChat::Client.new(hc_token, :api_version => 'v2', :server_url => "https://#{hc_server}")
end


client[hc_room].send(name_of_sender, message, notify: true, color: 'green')


__END__

client[hc_room].send(name_of_sender, 'I talk')

# Send notifications to users (default false)
client[hc_room].send(name_of_sender, 'I quit!', :notify => true)

# Color it red. or "yellow", "green", "purple", "random" (default "yellow")
client[hc_room].send(name_of_sender, 'Build failed!', :color => 'red')

# Have your message rendered as text in HipChat (see https://www.hipchat.com/docs/apiv2/method/send_room_notification)
client[hc_room].send(name_of_sender, '@coworker Build faild!', :message_format => 'text')

# Update the topic of a room in HipChat (see https://www.hipchat.com/docs/apiv2/method/set_topic)
client[hc_room].topic('Free Ice Cream in the kitchen')

# Change the from field for a topic update (default "API")
client[hc_room].topic('Weekely sales: $10,000', :from => 'Sales Team')

# Get history from a room
client[hc_room].history()

# Get history for a date in time with a particular timezone (default is latest 75 messages, timezone default is 'UTC')
client[hc_room].history(:date => '2010-11-19', :timezone => 'PST')

# Create a new room (see https://www.hipchat.com/docs/apiv2/method/create_room)
client.create_room("Name", options = {})

# Get room data (see https://www.hipchat.com/docs/apiv2/method/get_room)
client[hc_room].get_room

# Update room data (see https://www.hipchat.com/docs/apiv2/method/update_room)
It's easiest to call client[hC_Room].get_room, parse the json and then pass in modified hash attributes
client[hc_room].update_room(options = {})

# Invite user to room (see https://www.hipchat.com/docs/apiv2/method/invite_user)
client[hc_room].invite("USER_ID_OR_NAME", options = {})

# Sends a user a private message. Valid value for user are user id or email address
client.user('foo@bar.org').send('I can send private messages')
