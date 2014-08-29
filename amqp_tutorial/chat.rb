#!/usr/bin/env ruby
###########################################################
###
##  File:  chat.rb
##  Desc:  Demo of using amqp and event machine
#
#
# sudo gem install amqp
# sudo port install python25 rabbitmq-server
# sudo rabbitmq-server
###########################################################
# A startup item has been generated that will aid in
# starting rabbitmq-server with launchd. It is disabled
# by default. Execute the following command to start it,
# and to cause it to launch at startup:
#
# sudo launchctl load -w /Library/LaunchDaemons/org.macports.rabbitmq-server.plist
###########################################################


require 'rubygems'
gem 'amqp'
require 'mq'

unless ARGV.length == 2
  STDERR.puts "Usage: #{$0} <channel> <nick>"
  exit 1
end
$channel, $nick = ARGV

AMQP.start(:host => 'localhost') do
  $chat = MQ.topic('chat')

  # Print any messages on our channel.
  queue = MQ.queue($nick)
  queue.bind('chat', :key => $channel)
  queue.subscribe do |msg|
    if msg.index("#{$nick}:") != 0
      puts msg
    end
  end

  # Forward console input to our channel.
  module KeyboardInput
    include EM::Protocols::LineText2
    def receive_line data
      $chat.publish("#{$nick}: #{data}",
                    :routing_key => $channel)
    end
  end
  EM.open_keyboard(KeyboardInput)
end