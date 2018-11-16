#!/usr/bin/env ruby
# kafka/test_kafka.rb
# Playing with Kafka as a potentional replacement for RabbitMQ

require_relative 'config_kafka'

stars = "*" * 55

debug_me('INSIDE the test pgm'){[ :KAFKA ]}

puts stars
puts KAFKA.methods.sort
puts stars



# create a new topic
topic_name = 'my_topic_name'

KAFKA.create_topic(
  topic_name,
  num_partitions:     3,
  replication_factor: 2,
  config: {
    "max.message.bytes" => 100000
  }
)


# get an array of strings - the topics available
# on this kafka cluster
debug_me{[ 'KAFKA.topics' ]}


debug_me{[ 'KAFKA.topics' ]}


KAFKA.create_partitions_for(topic_name, num_partitions: 10)

# This will write the message to a random partition in the greetings topic. If you want to write to a specific partition, pass the partition parameter:

KAFKA.deliver_message("Hello, World!", topic: topic_name)

# Get some information about a topic
KAFKA.describe_topic(topic_name, ["max.message.bytes", "retention.ms"])
# => {"max.message.bytes"=>"100000", "retention.ms"=>"604800000"}

# Change a topic's configuration
KAFKA.alter_topic(topic_name, "max.message.bytes" => 100000, "retention.ms" => 604800000)

KAFKA.delete_topic(topic_name)


# Will write to partition 42.

KAFKA.deliver_message("Hello, World!", topic: topic_name, partition: 42)


# If you don't know exactly how many partitions are in the topic, or if you'd rather have some level of indirection, you can pass in partition_key instead. Two messages with the same partition key will always be assigned to the same partition. This is useful if you want to make sure all messages with a given attribute are always written to the same partition, e.g. all purchase events for a given customer id.

# Partition keys assign a partition deterministically.

KAFKA.deliver_message("Hello, World!", topic: topic_name, partition_key: "hello")



# Kafka also supports message keys. When passed, a message key can be used instead of a partition key. The message key is written alongside the message value and can be read by consumers. Message keys in Kafka can be used for interesting things such as Log Compaction. See Partitioning for more information.

# Set a message key; the key will be used for partitioning since no explicit `partition_key` is set.
KAFKA.deliver_message("Hello, World!", key: "hello", topic: topic_name)


# Efficiently Producing Messages

# While #deliver_message works fine for infrequent writes, there are a number of downsides:

#   * Kafka is optimized for transmitting messages in batches rather than individually, so there's a significant overhead and performance penalty in using the single-message API.
#   * The message delivery can fail in a number of different ways, but this simplistic API does not provide automatic retries.
#   * The message is not buffered, so if there is an error, it is lost.

# The Producer API solves all these problems and more:

# Instantiate a new producer.
producer = KAFKA.producer

another_topic_name = "another_topic_name"

# Add a message to the producer buffer.
producer.produce("hello1", topic: another_topic_name)

# Deliver the messages to Kafka.
producer.deliver_messages


# `#async_producer` will create a new asynchronous producer.
producer = KAFKA.async_producer

# The `#produce` API works as normal.
producer.produce("hello", topic: another_topic_name)

# `#deliver_messages` will return immediately.
producer.deliver_messages

# Make sure to call `#shutdown` on the producer in order to avoid leaking
# resources. `#shutdown` will wait for any pending messages to be delivered
# before returning.
producer.shutdown


# `async_producer` will create a new asynchronous producer.
producer = KAFKA.async_producer(
  # Trigger a delivery once 10 messages have been buffered.
  delivery_threshold: 10,

  # Trigger a delivery every 30 seconds.
  delivery_interval: 30,

  # Allow at most 5K messages to be buffered.
  max_buffer_size: 5_000,

  # Allow at most 100MB to be buffered.
  max_buffer_bytesize: 100_000_000,

  # This is the default: all replicas must acknowledge.
  required_acks: :all, # highly recommended to use this default setting

  # This is fire-and-forget: messages can easily be lost.
  required_acks: 0,

  # This only waits for the leader to acknowledge.
  required_acks: 1,

  # The number of retries when attempting to deliver messages. The default is
  # 2, so 3 attempts in total, but you can configure a higher or lower number:
  max_retries: 5,

  # The number of seconds to wait between retries. In order to handle longer
  # periods of Kafka being unavailable, increase this number. The default is
  # 1 second.
  retry_backoff: 5,

  compression_codec: :snappy,  # or :gzip, :lz4
  compression_threshold: 10,
)

25.times do |message_number|
  producer.produce("hello-#{message_number}", topic: another_topic_name)
end


event = {
  "name" => "pageview",
  "url" => "https://example.com/posts/123",
  # ...
}

data = JSON.dump(event)

producer.produce(data, topic: another_topic_name)

# However, sometimes it's necessary to select a specific partition. When doing this, make sure that you don't pick a partition number outside the range of partitions for the topic:

partitions = KAFKA.partitions_for(another_topic_name) # returns integer number of partitions for the thing

# Make sure that we don't exceed the partition count!
partition = some_number % partitions

producer.produce(event, topic: another_topic_name, partition: partition)


##############################################
## Receiving messages

KAFKA.each_message(topic: another_topic_name) do |message|
  # puts message.offset, message.key, message.value
  debug_me {[ :message ]}
end

# Consumers with the same group id will form a Consumer Group together.
consumer = KAFKA.consumer(
  group_id: "some-group",

  # Increase offset commit frequency to once every 5 seconds.
  offset_commit_interval: 5,

  # Commit offsets when 100 messages have been processed.
  offset_commit_threshold: 100,

  # Increase the length of time that committed offsets are kept.
  offset_retention_time: 7 * 60 * 60
)
# It's possible to subscribe to multiple topics by calling `subscribe`
# repeatedly.
consumer.subscribe(
  another_topic_name,
  # Consume messages from the very beginning of the topic. This is the default.
  start_from_beginning: true, # false means only consume new messages.

)

# Stop the consumer when the SIGTERM signal is sent to the process.
# It's better to shut down gracefully than to kill the process.
trap("TERM") { consumer.stop }

# This will loop indefinitely, yielding each message in turn.
consumer.each_message do |message|
  # puts message.topic, message.partition
  # puts message.offset, message.key, message.value
  debug_me {[ :message ]}
end


# For some use cases it may be necessary to control when messages are marked as processed. Note that since only the consumer position within each partition can be saved, marking a message as processed implies that all messages in the partition with a lower offset should also be considered as having been processed.

# The method Consumer#mark_message_as_processed marks a message (and all those that precede it in a partition) as having been processed. This is an advanced API that you should only use if you know what you're doing.

# Manually controlling checkpointing:

# Typically you want to use this API in order to buffer messages until some
# special "commit" message is received, e.g. in order to group together
# transactions consisting of several items.
buffer = []

# Messages will not be marked as processed automatically. If you shut down the
# consumer without calling `#mark_message_as_processed` first, the consumer will
# not resume where you left off!
consumer.each_message(automatically_mark_as_processed: false) do |message|
  # Our messages are JSON with a `type` field and other stuff.
  event = JSON.parse(message.value)

  case event.fetch("type")
  when "add_to_cart"
    buffer << event
  when "complete_purchase"
    # We've received all the messages we need, time to save the transaction.
    save_transaction(buffer)

    # Now we can set the checkpoint by marking the last message as processed.
    consumer.mark_message_as_processed(message)

    # We can optionally trigger an immediate, blocking offset commit in order
    # to minimize the risk of crashing before the automatic triggers have
    # kicked in.
    consumer.commit_offsets

    # Make the buffer ready for the next transaction.
    buffer.clear
  end
end
