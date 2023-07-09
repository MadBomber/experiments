#!/usr/bin/env ruby
# smart_bunny_chat.rb

require 'bunny'   # Popular easy to use Ruby client for RabbitMQ
require 'openai'  # OpenAI API + Ruby! 🤖❤️

require 'terminal-size'  # A tiny gem to accomplish a simple task: Determining the terminal size.
require 'word_wrapper'   # Pure ruby word wrapping


class AI
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
  end

  def ask(prompt)
    response = @client.chat(
        parameters: {
            model: "gpt-3.5-turbo", # Required.
            messages: [{ role: "user", content: prompt}], 
            temperature: 0.7,
        })

    # debug_me{[ :response ]}

    return response.dig("choices", 0, "message", "content")
  end
end


class SmartBunnyChat
  WIDTH = Terminal.size[:width] - 4

  def initialize(
      username: ENV.fetch('USERNAME', 'Guest'), 
      host:     'localhost', 
      port:     5672
    )

    @ai         = AI.new
    @username   = username
    @connection = Bunny.new(host: host, port: port)
    @channel    = nil
    @exchange   = nil
    @queue      = nil
  end

  def run
    begin
      @connection.start
    rescue Bunny::TCPConnectionFailedForAllHosts => e
      show "Error: #{e.message}"
      return
    end

    @channel  = @connection.create_channel

    # TODO: Change to a "topic" exchange.
    @exchange = @channel.fanout('notifications')

    @queue    = @channel.queue('', exclusive: true)
    @queue.bind(@exchange)

    Thread.new { read_user_input }

    @queue.subscribe(block: true) do |delivery_info, properties, body|
      if body.start_with?('/')
        parts   = body.strip.split
        command = parts.shift[1..]
        params  = parts.join(" ")

        if respond_to?(command)
          send(command, params)
        else
          show "Unknown command: #{command}"
        end
      else
        show body
      end
    end
  end

  def read_user_input
    loop do
      message = gets.chomp

      if message.start_with?('/')
        parts   = message.strip.split
        command = parts.shift[1..]
        params  = parts.join(" ")

        if respond_to?(command)
          if "ask" == command
            @exchange.publish( ask(params) )
          else
            @exchange.publish(message)
          end
        else
          show "Unknown command: #{command}"
        end
      else
        @exchange.publish("#{@username}: #{message}") unless message.empty?
      end
    end
  end


  # Publishes a message to the RabbitMQ message broker.
  #
  # @param message [String] The message to publish.
  # @param routing_key [String] The routing key to use.
  # @param username [String] The username of the user who sent the message.
  def publish(message, routing_key, username)
    headers = { "username" => username }
    @exchange.publish(message, routing_key: routing_key, headers: headers)
  end


  def show(a_string)
    paragraphs = a_string.split("\n")
    paragraphs.each do |text|
      lines = WordWrapper::MinimumRaggedness.new(WIDTH, text).wrap.split("\n")
      lines.each do |a_line|
        puts "  " + a_line
      end
    end
    puts
  end


  def here(...)
    @exchange.publish(@username)
  end

  def stop(...)
    @connection.close
    exit
  end

  def ask(prompt=nil)
    return "You forgot to ask ..." if prompt.nil?
    "#{@username}: FYI ...\n" + @ai.ask(prompt)
  end
end

Signal.trap('INT') do
  show "Use the command /stop instead of cntl-c"
end

SmartBunnyChat.new().run




__END__

TODO: change exchange from a fan out to a topic.split

Support direct messaging between users. 

Support following other users. 

session = Bunny.new
session.start

exchange = session.exchange("users", type: :topic)

username = "user1"
to_username = "user2"
message = "Hello, user2!"

routing_key = "users.#{to_username}.#{username}"
exchange.publish(message, routing_key: routing_key)

A routhing key of "#{channel}.*.*" sends/receives all messages to the channel 

A routing_key of "users.#{username}.*" gets all direct messaged to "me" from any other users 

how to support subscribe and unsubscribe to channels 
in a topic-based exchange 

session = Bunny.new
session.start

exchange = session.exchange("chat", type: :topic)

# Subscribe user1 to the "general" topic
user1_queue = session.queue("user1")
user1_queue.bind(exchange, routing_key: "general.*")

# Subscribe user2 to the "general" and "news" topics
user2_queue = session.queue("user2")
user2_queue.bind(exchange, routing_key: "general.*")
user2_queue.bind(exchange, routing_key: "news.*")

# Unsubscribe user2 from the "news" topic
user2_queue.unbind(exchange, routing_key: "news.*")

require "bunny"
require_relative "commander"

class SmartBunnyChat
  def initialize(username)
    @username = username
    @session = Bunny.new
    @session.start
    @exchange = @session.exchange("chat", type: :topic)
    @subscriptions = {}

    # Automatically subscribe the user to the "general" and "random" channels
    subscribe(["general", "random"])

    # Save an instance of the Commander class
    @commander = Commander.new(@session)
  end

  def run
    Thread.new { read_user_input }

    loop do
      process_next_message
    end
  end

  # Subscribes the user to a list of channels.
  #
  # @param channels [Array<String>] The list of channels to subscribe to.
  def subscribe(channels)
    channels.each do |channel|
      queue_name = "#{@username}-#{channel}"
      queue = @session.queue(queue_name)
      if queue.exists?
        queue.bind(@exchange, routing_key: "#{channel}.*")
        @subscriptions[channel] = queue_name
      else
        queue = @session.queue(queue_name)
        queue.bind(@exchange, routing_key: "#{channel}.*")
        @subscriptions[channel] = queue_name
        queue.subscribe do |delivery_info, properties, body|
          process_message(channel, body)
        end
      end
    end
  end

  # Unsubscribes the user from a list of channels.
  #
  # @param channels [Array<String>] The list of channels to unsubscribe from.
  def unsubscribe(channels)
    channels.each do |channel|
      queue_name = @subscriptions[channel]
      if queue_name
        queue = @session.queue(queue_name)
        if queue.exists?
          queue.unbind(@exchange, routing_key: "#{channel}.*")
          queue.unsubscribe
          @subscriptions.delete(channel)
        else
          puts "The #{channel} channel does not exist."
        end
      end
    end
  end

  private

  # Processes the next message available from any subscribed channel.
  def process_next_message
    @subscriptions.each do |channel, queue_name|
      queue = @session.queue(queue_name)
      delivery_info, properties, body = queue.pop
      if body
        @commander.process_message(channel, body)
      end
    end
  end

  # Processes a message from a channel.
  #
  # @param channel [String] The channel the message was received on.
  # @param message [String] The message to process.
  def process_message(channel, message)
    @commander.process_message(channel, message)
  end
end





