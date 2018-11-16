#!/usr/bin/env ruby
# kafka/config_kafka.rb

# Must match the server name in config/kafka.properties
KAFKA_HOST = 'localhost'  # `hostname`.chomp

require "json"            # STDLIB
require 'logger'          # STDLIB
logger = Logger.new("kafka.log")

require 'awesome_print'   # Pretty print Ruby objects with proper indentation and colors

require 'debug_me'        # A tool to print the labeled value of variables.
include DebugMe

require 'kick_the_tires'  # Provides some basic methods/assertions that are handy for exploring a new ruby library.
include KickTheTires

require "kafka" # gem 'ruby-kafka' - A client library for the Kafka distributed commit log.



# The first argument is a list of "seed brokers" that will be queried for the full
# cluster topology. At least one of these *must* be available. `client_id` is
# used to identify this client in logs and metrics. It's optional but recommended.
KAFKA = Kafka.new(
  ["#{KAFKA_HOST}:9092"], # one or more (in Array) kafka instances in the cluster
  client_id: "my-application",
  logger: logger, # always a good idea in development

  # encrypt comms with SSL
  # ssl_ca_cert: File.read('my_ca_cert.pem'), # optional
  # ssl_ca_certs_from_system: true, # pr use the system store
  # ssl_client_cert: File.read('my_client_cert.pem'),
  # ssl_client_cert_key: File.read('my_client_cert_key.pem'),

  # or use a login as an option
  # sasl_plain_username: 'username',
  # sasl_plain_password: 'password'
)

debug_me{[ :KAFKA ]}



