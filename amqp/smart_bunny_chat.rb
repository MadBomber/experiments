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
    @exchange = @channel.fanout('notifications')
    @queue    = @channel.queue('', exclusive: true)
    @queue.bind(@exchange)

    Thread.new { read_user_input }

    @queue.subscribe(block: true) do |delivery_info, properties, body|
      if body.start_with?('/')
        parts   = body.strip.split
        command = parts.shift[1..-1]
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
        command = parts.shift[1..-1]
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
