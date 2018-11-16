require 'debug_me'
include DebugMe

require "kafka"

K1 = Kafka.new(["172.17.0.1:9092"], client_id: "ruby-kafka")

