#!/usr/bin/env ruby
# sbc2.rb

require 'debug_me'
include DebugMe

require "bunny"
require "openai"

class SmartBunnyChat
  COMMON_CHANNELS = "general random"

  def initialize(username: ENV['USERNAME'] || "Guest")
    @username       = username
    @session        = Bunny.new().start
    @users          = []
    @muted_channels = []
    @muted_users    = []
    @subscriptions  = {}

    subscribe COMMON_CHANNELS
  end

  def run
    Thread.new { read_user_input }

    loop do
      process_next_message
    end
  end



  # Processes a message and executes the corresponding command.
  #
  # @param message [Bunny::Message] The message to process.
  # @return [Boolean] True if the message was a command, false otherwise.
  def process(channel, message)

    debug_me{[ :channel, :message ]}


    if message[:payload].start_with?("/")
      parts       = message[:payload].split(' ')
      method_name = parts.shift()[1..]
      params      = parts.join(' ')

      if respond_to?(method_name)
        send(method_name, params)
      else
        puts "Unknown command: #{command}"
      end

      return true
    else
      username = message[:headers]["username"]
      @users << username unless @users.include?(username)
      
      show(channel, username, message[:payload])

      return false
    end
  end


  # Mutes one or more channels and/or users.
  #
  # @param params [Array<String>] The list of channels and/or users to mute.
  def mute(*params)
    channels, users = split_params(params)

    channels.each do |channel|
      if @channels.include?(channel) && !@muted_channels.include?(channel)
        @muted_channels << channel
        puts "Muted channel #{channel}"
      end
    end

    users.each do |user|
      unless @muted_users.include?(user)
        @muted_users << user
        puts "Muted user #{user}"
      end
    end
  end

  # Unmutes one or more channels and/or users.
  #
  # @param params [Array<String>] The list of channels and/or users to unmute.
  def unmute(*params)
    channels, users = split_params(params)

    channels.each do |channel|
      if @channels.include?(channel) && @muted_channels.include?(channel)
        @muted_channels.delete(channel)
        puts "Unmuted channel #{channel}"
      end
    end

    users.each do |user|
      if @muted_users.include?(user)
        @muted_users.delete(user)
        puts "Unmuted user #{user}"
      end
    end
  end

  # Lists all channels and their mute status.
  #
  # @param params [Array<String>] Unused.
  def channels(*params)
    puts "Channels:"

    @channels.each do |channel|
      muted = @muted_channels.include?(channel)
      puts "#{channel}#{muted ? ' (muted)' : ''}"
    end
  end

  # Lists all users and their mute status.
  #
  # @param params [Array<String>] Unused.
  def users(*params)
    puts "Users:"

    @users.each do |user|
      muted = @muted_users.include?(user)
      puts "#{user}#{muted ? ' (muted)' : ''}"
    end
  end


  # Subscribes the user to a list of channels.
  #
  # @param channels_string The list of channels to subscribe to.
  def subscribe(channels_string)
    channels = channels_string.split.map{|c| c.gsub('#','')}

    channels.each do |my_channel|
      next if @subscriptions.has_key? my_channel

      channel   = @session.create_channel
      exchange  = channel.topic(my_channel)
      queue     = channel.queue("#{channel}_queue")

      queue.bind(exchange, routing_key: "#{my_channel}.*")

      @subscriptions[my_channel] = {
        exchange: exchange,
        queue:    queue
      }

      Thread.new do 
        queue.subscribe do
          process_message( next_message_from(queue) )
        end
      end
    end
  end

  # Unsubscribes the user from a list of channels.
  #
  # @param channels_string The list of channels to unsubscribe from.
  def unsubscribe(channels_string)
    channels = channels_string.split

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

  ################################################
  private
  
  # Processes the next message available from any subscribed channel.
  def process_next_message
      @subscriptions.each_pair do |channel, session|
        queue   = session[:queue]
        message = next_message_from(queue)

        process(channel, message) if message
      end
  end


  # Helper method to get the next Bunny::Message object from the given queue.
  #
  # @param queue [Bunny::Queue] The queue to get the message from.
  # @return [Bunny::Message, nil] The next Bunny::Message object or nil if no message is available.
  def next_message_from(queue)
    delivery_info, properties, body = queue.pop
    return nil if body.nil?
    Bunny::Message.new(delivery_info, properties, body)
  end


  # Splits the parameters into channels and users.
  #
  # @param params [Array<String>] The list of parameters to split.
  # @return [Array<Array<String>>] The list of channels and users.
  def split_params(params)
    channels  = params.select { |param| param.start_with?("#") }.map { |param| param[1..] }
    users     = params.select { |param| param.start_with?("@") }.map { |param| param[1..] }
    
    return channels, users
  end
end


SmartBunnyChat.new().run 
