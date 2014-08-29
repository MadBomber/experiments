#!/usr/bin/env ruby
#################################################################
###
## 	File: lets_not_race.rb
## 	Desc: nessage passing via AMQP between two processes
##
## 			http://graysoftinc.com/rubies-in-the-rough/sleepy-programs?utm_source=rubyweekly&utm_medium=email
#

require "benchmark"
require "thread"

require "bunny"

QUEUE_NAME = "example"
MESSAGES   = %w[first second third]

def send_messages(*messages)
  connection = Bunny.new.tap(&:start)
  exchange   = connection.create_channel.default_exchange

  messages.each do |message|
    exchange.publish(message, routing_key: QUEUE_NAME)
  end

  connection.close
end

def listen_for_messages(received_messages, check_queue, listen_queue)
  connection = Bunny.new.tap(&:start)
  queue      = connection.create_channel.queue(QUEUE_NAME, auto_delete: true)

  queue.subscribe do |delivery_info, metadata, payload|
    received_messages << payload

    check_queue << :check
    listen_queue.pop
  end

  time_it("Received #{MESSAGES.size} messages") do
    yield
  end

  connection.close
end

def time_it(name)
  elapsed = Benchmark.realtime do
    yield
  end
  puts "%s: %.2fs" % [name, elapsed]
end

def wait_for_messages(received_messages, check_queue, listen_queue)
  loop do
    check_queue.pop

    break if received_messages == MESSAGES

    listen_queue << :listen
  end
end

def send_and_receive
  reader, writer = IO.pipe
  pid            = fork do
    writer.close

    reader.read
    reader.close

    send_messages(*MESSAGES)
  end
  Process.detach(pid)
  reader.close

  received_messages = [ ]
  check_queue       = Queue.new
  listen_queue      = Queue.new
  listen_for_messages(received_messages, check_queue, listen_queue) do
    writer.puts "ready"
    writer.close

    wait_for_messages(received_messages, check_queue, listen_queue)
  end
end

send_and_receive
