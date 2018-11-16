#!/usr/bin/env ruby
# kafka/send_messages.rb

require 'ruby-kafka'
require_relative 'config_kafka'


# Instantiate a new producer.
# PRODUCER = KAFKA.producer

def send(message, topic='greetings')
  # Add a message to the producer buffer.
  # PRODUCER.produce(message, topic: topic)

  # Deliver the messages to Kafka.
  # PRODUCER.deliver_messages

  KAFKA.deliver_message(message, topic: topic)
end

send "Hello World"
