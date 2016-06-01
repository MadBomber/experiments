#!/usr/bin/env ruby
# Source: https://github.com/rethinkdb/example-rabbitmq/blob/master/ruby/rabbit_listener.rb

require 'bunny'
require 'json'


# Setup the rabbit connection and queue
rabbit_conn = Bunny.new(:host => 'localhost', :port => 5672).start
channel = rabbit_conn.create_channel
exchange = channel.topic("rethinkdb", :durable => false)
queue = channel.queue('', :exclusive => true)

# Bind to all changes on the 'mytable' topic
queue.bind(exchange, :routing_key => 'mytable.*')

# Listen for changes and print them out
puts 'Started listening...'

queue.subscribe(:block => true) do |delivery_info, metadata, payload|
  change = JSON.parse(payload)
  tablename = delivery_info.routing_key.split('.')[0]
  puts "#{tablename} -> RabbitMQ -( #{delivery_info.routing_key} )-> Listener"
  puts JSON.pretty_generate(change)
  puts "="*80, "\n"
end