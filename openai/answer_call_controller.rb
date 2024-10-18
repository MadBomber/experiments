# experiments/openai/answer_call_controller.rb
# See: https://github.com/alexrudall/ruby-openai/issues/524

require "faye/websocket"
require "net/http"
require "eventmachine"

class AnswerCallController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_call
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say(message: "Connecting to the AI voice assistant...")
      r.connect do |c|
        c.stream(url: "wss://#{request.host_with_port}/media-stream")
      end
    end
    render xml: response.to_s
  end

  def media_stream
    if Faye::WebSocket.websocket?(request.env)
      ws = Faye::WebSocket.new(request.env)
      stream_sid = nil

      ws.on :open do |event|
        puts "Twilio client connected"
        # Connect to OpenAI WebSocket
        openai_ws = Faye::WebSocket::Client.new("wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01", nil, headers: {
          "Authorization" => "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}",
          "OpenAI-Beta" => "realtime=v1"
        })

        openai_ws.on :open do |event|
          puts "Connected to OpenAI Realtime API"
          # Send session update
          session_update = {
            type: "session.update",
            session: {
              turn_detection: { type: "server_vad" },
              input_audio_format: "g711_ulaw",
              output_audio_format: "g711_ulaw",
              voice: "alloy",
              instructions: "You are a helpful and bubbly AI assistant. You are brief and to the point.",
              modalities: [ "text", "audio" ],
              temperature: 0.8
            }
          }
          openai_ws.send(session_update.to_json)
        end

        openai_ws.on :message do |event|
          # Handle incoming messages from OpenAI
          begin
            data = JSON.parse(event.data)
            case data["type"]
            when "response.audio.delta"
              if data["delta"]
                begin
                  # Process audio delta
                  audio_delta = {
                    event: "media",
                    streamSid: stream_sid,
                    media: {
                      payload: data["delta"]
                    }
                  }
                  # Send audio delta to Twilio
                  ws.send(audio_delta.to_json)
                rescue => e
                  puts "Error processing audio delta: #{e.message}"
                end
              end
            when "session.updated"
              puts "Session updated successfully: #{data}"
            when "input_audio_buffer.speech_started"
              puts "Speech Start: #{data['type']}"
              handle_speech_started_event(ws, openai_ws, stream_sid)
            end
          rescue => e
            puts "Error processing OpenAI message: #{e.message}, Raw message: #{event.data}"
          end
        end

        openai_ws.on :close do |event|
          puts "Disconnected from OpenAI Realtime API"
        end

        openai_ws.on :error do |event|
          puts "WebSocket error: #{event.message}"
        end

        # Handle incoming messages from Twilio
        ws.on :message do |event|
          data = JSON.parse(event.data)
          if data["event"] == "media"
            begin
              # Forward media to OpenAI
              audio_append = {
                type: "input_audio_buffer.append",
                audio: data["media"]["payload"]
              }
              openai_ws.send(audio_append.to_json) if openai_ws.ready_state == Faye::WebSocket::OPEN
            rescue => e
              puts "Error processing Twilio audio: #{e.message}"
            end
          elsif data["event"] == "start"
            stream_sid = data["start"]["streamSid"]
            puts "Incoming stream has started: #{stream_sid}"
          end
        end

        ws.on :close do |event|
          puts "Twilio client disconnected"
          openai_ws.close if openai_ws.ready_state == Faye::WebSocket::OPEN
        end
      end

      # Return async Rack response
      ws.rack_response
    else
      # Handle non-WebSocket requests
      render plain: "This endpoint is for WebSocket connections only."
    end
  end

  private

  def handle_speech_started_event(ws, openai_ws, stream_sid)
    if ws.ready_state == Faye::WebSocket::OPEN
      # Send a clear event to Twilio to clear the media buffer
      ws.send({ streamSid: stream_sid, event: "clear" }.to_json)
      puts "Cancelling AI speech from the server"
    end

    if openai_ws.ready_state == Faye::WebSocket::OPEN
      # Send a cancel message to OpenAI to interrupt the AI response
      interrupt_message = { type: "response.cancel" }
      openai_ws.send(interrupt_message.to_json)
    end
  end
end

