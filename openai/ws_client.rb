# experiments/openai/ws_client.rb
# See: https://github.com/alexrudall/ruby-openai/issues/524

require "async"
require "async/http"
require "async/websocket"

def ws_client


  url = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01"

  # Creating headers for the request
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY", nil)}",
    "OpenAI-Beta" => "realtime=v1",
  }

  Async do |task|
    endpoint = Async::HTTP::Endpoint.parse(url, alpn_protocols: Async::HTTP::Protocol::HTTP11.names)

    Async::WebSocket::Client.connect(endpoint, headers: headers) do |connection|
      input_task = task.async do
        while line = $stdin.gets
          text = {
            type: "response.create",
            response: {
              modalities: ["text"],
              instructions: "Please assist the user.",
            },
          }
          message = Protocol::WebSocket::TextMessage.generate(text) # ({ text: line })
          message.send(connection)
          connection.flush
        end
      end

      puts "Connected..."
      while message = connection.read
        puts "> #{message.to_h}"
      end
    ensure
      input_task&.stop
    end
  end
end
