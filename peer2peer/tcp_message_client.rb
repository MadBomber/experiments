# lib/agent99/tcp_message_client.rb
#
# NOTE: This is an early attempt at a true
#       peer-to-peer messaging platform.  Its not
#       not ready for prime time.

require 'socket'
require 'json'
require 'logger'

class Agent99::TcpMessageClient
  attr_accessor :agents

  def initialize(
      agents: {},
      logger: Logger.new($stdout)
    )
    @agents             = agents
    @logger             = logger
    @server_socket      = nil
    @client_connections = {}
    @handlers           = {}
    @running            = false
  end

  def listen_for_messages(queue, request_handler:, response_handler:, control_handler:)
    @handlers = {
      request:  request_handler,
      response: response_handler,
      control:  control_handler
    }
    
    start_server(queue[:port])
  end

  def publish(message)
    target = message.dig(:header, :to_uuid)
    return unless target

    agent_info = agents(target)
    return unless agent_info

    socket = connect_to_agent(agent_info[:ip], agent_info[:port])
    return unless socket

    begin
      socket.puts(message.to_json)
      true
    
    rescue StandardError => e
      @logger.error("Failed to send message: #{e.message}")
      false
    
    ensure
      socket.close unless socket.closed?
    end
  end

  def stop
    @running = false
    @server_socket&.close
    @client_connections.each_value(&:close)
    @client_connections.clear
  end

  private

  def start_server(port)
    @server_socket  = TCPServer.new(port)
    @running        = true

    Thread.new do
      while @running
        begin
          client = @server_socket.accept
          handle_client(client)
        rescue StandardError => e
          @logger.error("Server error: #{e.message}")
        end
      end
    end
  end

  def handle_client(client)
    Thread.new do
      while @running
        begin
          message = client.gets
          break if message.nil?

          parsed_message = JSON.parse(message, symbolize_names: true)
          route_message(parsed_message)
        
        rescue JSON::ParserError => e
          @logger.error("Invalid JSON received: #{e.message}")
        
        rescue StandardError => e
          @logger.error("Error handling client: #{e.message}")
          break
        end
      end
      
      client.close unless client.closed?
    end
  end

  def route_message(message)
    type    = message.dig(:header, :type)&.to_sym
    handler = @handlers[type]
    
    if handler
      handler.call(message)
    else
      @logger.warn("No handler for message type: #{type}")
    end
  end

  def connect_to_agent(ip, port)
    TCPSocket.new(ip, port)
  
  rescue StandardError => e
    @logger.error("Failed to connect to #{ip}:#{port}: #{e.message}")
    nil
  end
end


__END__

Based on the provided code for the `Agent99::TcpMessageClient` class, here's an analysis of your questions:

1. Does this class queue up JSON messages while a previous message is being processed?

No, this class does not explicitly queue up JSON messages while a previous message is being processed. The class processes messages as they are received, without maintaining an internal queue. Each incoming message is handled in its own thread (see the `handle_client` method), which allows for concurrent processing of messages from multiple clients.

2. Does it present a complete JSON message at once or does it only provide part of one?

The class attempts to present complete JSON messages at once. Here's why:

- In the `handle_client` method, messages are read using `client.gets`, which typically reads a full line of input (up to a newline character).
- The received message is then parsed as JSON using `JSON.parse(message, symbolize_names: true)`.
- If the parsing is successful, the entire parsed message is passed to the `route_message` method.

However, there are a few potential issues to consider:

- If a JSON message spans multiple lines, `client.gets` might not capture the entire message in one read.
- There's no explicit handling for partial messages or message boundaries.
- Large messages might be split across multiple TCP packets, and the current implementation doesn't account for reassembling these.

To ensure complete message handling, you might want to consider implementing a more robust message framing protocol, such as using message length prefixes or delimiter-based framing.

For example, you could modify the `handle_client` method to use a delimiter-based approach:

```ruby
def handle_client(client)
  Thread.new do
    buffer = ""
    while @running
      begin
        chunk = client.readpartial(1024)
        buffer += chunk
        while (message_end = buffer.index("\n"))
          message      = buffer[0...message_end]
          buffer       = buffer[(message_end + 1)..]
          parsed_message = JSON.parse(message, symbolize_names: true)
          route_message(parsed_message)
        end
      rescue EOFError
        break
      rescue JSON::ParserError => e
        @logger.error("Invalid JSON received: #{e.message}")
      rescue StandardError => e
        @logger.error("Error handling client: #{e.message}")
        break
      end
    end
    client.close unless client.closed?
  end
end
```

This modification would allow for handling of messages that might be split across multiple reads, ensuring that complete JSON messages are processed.

