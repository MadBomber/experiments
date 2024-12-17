# one.rb

require_relative 'common_config'
require_relative 'tcp_message_client'

client = Agent99::TcpMessageClient.new(agents: AGENTS)

# Start listening for messages
client.listen_for_messages(
  AGENTS[:one],
  request_handler:  ->(msg) { puts "One received request: #{msg}" },
  response_handler: ->(msg) { puts "One received response: #{msg}" },
  control_handler:  ->(msg) { puts "One received control: #{msg}" }
)

loop do
  print "Enter destination (two/three) or 'quit': "
  destination = gets.chomp.downcase
  break if destination == 'quit'

  print "Enter message: "
  message = gets.chomp

  client.publish({
    header: {
      type:       :request,
      to_uuid:    destination.to_sym,
      from_uuid:  :one
    },
    payload: { message: message }
  })
end

client.stop
