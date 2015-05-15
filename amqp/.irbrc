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

class MeditationSubmissionConsumer < Bunny::Consumer

  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end

end # class MeditationSubmissionConsumer < Bunny::Consumer

$consumer = MeditationSubmissionConsumer.new($channel, $queue, "elvis_eats_meditations", false, false)

