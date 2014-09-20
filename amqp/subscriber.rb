#!/usr/bin/env ruby
#################################################################
###
##  File: subscriber.rb
##  Desc: Subscribe to meditation submissions
##
#
require 'awesome_print'

#####################################################
## initializer junk

require "bunny"
require 'json'
require 'hashie'
require 'date'

OPTIONS = {
  :host      => "localhost",          # defualt: 127.0.0.1
  :port      => 5672,                 # default
  :ssl       => false,                # defualt
  :vhost     => "sandbox",            # defualt: /
  :user      => "xyzzy",              # defualt: guest
  :pass      => "xyzzy",              # defualt: guest
  :heartbeat => :server,              # defualt: will use RabbitMQ setting
  :threaded  => true,                 # default
  :network_recovery_interval => 5.0,  # default is in seconds
  :automatically_recover  => true,    # default
  :frame_max => 131072                # default
}

QUEUE_NAME = "submissions"

connection = Bunny.new(OPTIONS).tap(&:start)
channel    = connection.create_channel
exchange   = channel.topic("sandbox", :auto_delete => true)

queue      = channel.queue( QUEUE_NAME,
                                durable: true,
                                auto_delete: false,
                                arguments: {"x-max-length" => 1000}
                            ).bind(exchange, :routing_key => "#.new")

at_exit do
  connection.close
end

#####################################################
## local stuff

class Author < Hashie::Mash
  def save
    # TODO: most likely going to save to a database
    #       or maybe to a file in Elvis

    puts "\nSaving New Author"
    puts "\tID ...... #{author_id}"
    puts "\tName .... #{name}"
    puts "\teMail ... #{email}"

    #sleep(1)

  end
end

class Meditation < Hashie::Mash
  def save
    # TODO: save as an InCopy file
    # TODO: Upload file to Elvis

    puts "\nSaving New Meditation"
    puts "\tID .......... #{submission_id}"
    puts "\tAuthor ID ... #{author_id}"
    puts "\tTheme ....... #{theme}"
    puts "\tTitle ....... #{title}"

    #sleep(1)

  end
end




class MeditationSubmissionConsumer < Bunny::Consumer

  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end

end # class MeditationSubmissionConsumer < Bunny::Consumer

consumer = MeditationSubmissionConsumer.new(
  channel,
  queue,
  "elvis_eats_meditations", # consumer tag
  false,                    # no_ack
  false                     # exclusive
)

consumer.on_delivery() do |delivery_info, metadata, payload|

    puts
    puts "#"*55
    print 'Routing Key: '
    puts delivery_info.routing_key

    begin
      payload_as_hash = JSON.parse(payload)
      submission = eval(delivery_info.routing_key + "(payload_as_hash)")
      begin
        submission.save
        consumer.channel.acknowledge( delivery_info.delivery_tag, false )
      rescue Exception => e
        puts "ERROR: had a problem saving #{e}"
      end

    rescue Exception => e
      puts "ERROR: Don't know: #{e}"
    end

end # consumer.on_delivery() do |delivery_info, metadata, payload|


queue.subscribe_with( consumer, block: true )

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

