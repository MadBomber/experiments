# two.rb

require_relative 'common_config'
require_relative 'tcp_message_client'

client = Agent99::TcpMessageClient.new(agents: AGENTS)

# Start listening for messages
client.listen_for_messages(
  AGENTS[:two],
  request_handler:  ->(msg) { puts "Two received request: #{msg}" },
  response_handler: ->(msg) { puts "Two received response: #{msg}" },
  control_handler:  ->(msg) { puts "Two received control: #{msg}" }
)

loop do
  print "Enter destination (one/three) or 'quit': "
  destination = gets.chomp.downcase
  break if destination == 'quit'

  print "Enter message: "
  message = gets.chomp

  client.publish({
    header: {
      type:       :request,
      to_uuid:    destination.to_sym,
      from_uuid:  :two
    },
    payload: { message: message }
  })
end

client.stop
