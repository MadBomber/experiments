#!/usr/bin/env ruby
#################################################################
###
##  File: subscriber.rb
##  Desc: Subscribe to meditation submissions
##
#
require 'awesome_print'
require 'debug_me'
require 'betterlorem'

#####################################################
## initializer junk

require "bunny"
require 'json'
require 'date'

OPTIONS = {
  :host      => "localhost",  # defualt: 127.0.0.1
  :port      => 5672,         # default
  :ssl       => false,        # defualt
  :vhost     => "sandbox",    # defualt: /
  :user      => "xyzzy",      # defualt: guest
  :pass      => "xyzzy",      # defualt: guest
  :heartbeat => :server,      # defualt: will use RabbitMQ setting
  :threaded  => true,         # default
  :network_recovery_interval => 5.0, # default is in seconds
  :automatically_recover  => true,  # default
  :frame_max => 131072        # default
}

QUEUE_NAME = "meditations"

$connection = Bunny.new(OPTIONS).tap(&:start)
$channel    = $connection.create_channel

$channel.queue_declare(QUEUE_NAME,
                        durable: true,
                        auto_delete: false,
                        arguments: {"x-max-length" => 1000})

$queue      = $channel.queue( QUEUE_NAME,
                                durable: true,
                                auto_delete: false,
                                arguments: {"x-max-length" => 1000}
                            )


#####################################################
## local stuff

class MeditationSubmissionConsumer < Bunny::Consumer

  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end

end # class MeditationSubmissionConsumer < Bunny::Consumer

consumer = MeditationSubmissionConsumer.new(
  $channel,
  $queue,
  "elvis_eats_meditations", # consumer tag
  false,                    # no_ack
  false                     # exclusive
)

consumer.on_delivery() do |delivery_info, metadata, payload|
    meditation = JSON.parse(payload, symbolize_names: true)
    puts
    puts "#"*55
    ap delivery_info
    ap metadata
    ap meditation
    consumer.channel.acknowledge( delivery_info.delivery_tag, false )
end

$queue.subscribe_with( consumer, block: true )

__END__





#loop do
  $queue.subscribe( :consumer_tag => "elvis_eats_meditations",
                    :block => true,
                    :ack => true) do |delivery_info, metadata, payload|

    meditation = JSON.parse(payload, symbolize_names: true)

    puts
    puts "#"*55
    ap delivery_info
    ap metadata
    ap meditation

    $channel.acknowledge( delivery_info.delivery_tag, false )
    $channel.reject(delivery_info.delivery_tag)       # reject and discard a message
    $channel.reject(delivery_info.delivery_tag, true) # reject but re-queque for another attempt later

  end
#end


$connection.close


__END__

System environment variables used when present:

RABBITMQ_URL

