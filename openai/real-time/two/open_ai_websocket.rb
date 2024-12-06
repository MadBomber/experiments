# app/services/open_ai_websocket.rb
class OpenAiWebsocket
  URL = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01"

  def initialize(session_id)
    @api_key = Rails.application.credentials.open_ai[:api_key]
    @session_id = session_id
    @ws = nil
    @message_queue = Queue.new
    @connected = false
  end

  def headers
    {
      "Authorization" => "Bearer #{@api_key}",
      "OpenAI-Beta" => "realtime=v1"
    }
  end

  def connect
    Thread.new { run_eventmachine }
    wait_for_connection
  end

  def run_eventmachine
    EM.run do
      puts "Connecting to OpenAI WebSocket..."
      @ws = Faye::WebSocket::Client.new(URL, nil, headers:)
      puts "DateTime: #{DateTime.now}"
      setup_response_handlers
      setup_event_handlers

      EM.add_periodic_timer(0.1) { process_message_queue }
    end
  end

  def wait_for_connection
    sleep 0.1 until @connected
  end

  def process_message_queue
    until @message_queue.empty?
      message = @message_queue.pop
      send_message(message)
    end
  end

  def enqueue_message(message)
    @message_queue.push(message)
  end

  def session_update(event_id:)
    enqueue_message({
      event_id: event_id,
      type: "session.update",
      session: {
        turn_detection: {
          type: "server_vad",
          threshold: 0.5,
          prefix_padding_ms: 300,
          silence_duration_ms: 200
        }
      }
    })
  end

  alias_method :update_session, :session_update

  def input_audio_buffer_append(audio_data)
    enqueue_message({
      event_id: "event_456",
      type: "input_audio_buffer.append",
      audio: audio_data
    })
  end

  alias_method :append_audio_buffer, :input_audio_buffer_append

  def input_audio_buffer_commit(event_id: nil)
    enqueue_message({
      event_id: event_id,
      type: "input_audio_buffer.commit"
    })
  end

  alias_method :commit_audio_buffer, :input_audio_buffer_commit

  def input_audio_buffer_clear(event_id: nil)
    enqueue_message({
      event_id: event_id,
      type: "input_audio_buffer.clear"
    })
  end

  alias_method :clear_audio_buffer, :input_audio_buffer_clear

  def conversation_item_create(item:, event_id: nil, previous_item_id: nil)
    enqueue_message({
      event_id: event_id,
      type: "conversation.item.create",
      previous_item_id: previous_item_id,
      item: item
    })
  end

  alias_method :create_conversation_item, :conversation_item_create

  def add_message(text, event_id: nil, previous_item_id: nil)
    conversation_item_create(
      item: {
        id: event_id,
        type: "message",
        status: "completed",
        role: "user",
        content: [
          {
            type: "input_text",
            text: text
          }
        ]
      },
      event_id:,
      previous_item_id:
    )
  end

  def conversation_item_truncate(item_id:, event_id: nil, content_index: 0, audio_end_ms: 1500)
    enqueue_message({
      event_id: event_id,
      type: "conversation.item.truncate",
      item_id: item_id,
      content_index: content_index,
      audio_end_ms: audio_end_ms
    })
  end

  alias_method :truncate_conversation_item, :conversation_item_truncate

  def conversation_item_delete(event_id:, item_id:)
    enqueue_message({
      event_id: event_id,
      type: "conversation.item.delete",
      item_id: item_id
    })
  end

  alias_method :delete_conversation_item, :conversation_item_delete

  def response_create(event_id: nil)
    enqueue_message({
      event_id: event_id,
      type: "response.create",
      response: {
        modalities: ["text", "audio"],
        instructions: "Please assist the user.  John Croucher is your awesome cofounder at Chick Commerce",
        voice: "alloy",
        output_audio_format: "pcm16",
        tools: [],
        tool_choice: "auto",
        temperature: 0.7,
        max_output_tokens: 150
      }
    })
  end

  alias_method :create_response, :response_create

  def response_cancel(event_id)
    enqueue_message({
      event_id: "#{event_id}",
      type: "response.cancel"
    })
  end

  alias_method :cancel_response, :response_cancel

  def append_audio(audio_data)
    enqueue_message({
      type: "input_audio_buffer.append",
      audio: audio_data
    })
  end

  def commit_audio
    enqueue_message({type: "input_audio_buffer.commit"})
  end

  def close
    @ws&.close
  end

  def response_handlers
    {
      :error => :handle_response_error,
      :"session.created" => :handle_session_created,
      :"session.updated" => :handle_session_updated,
      :"conversation.created" => :handle_conversation_created,
      :"input_audio_buffer.committed" => :handle_input_audio_buffer_committed,
      :"input_audio_buffer.cleared" => :handle_input_audio_buffer_cleared,
      :"input_audio_buffer.speech_started" => :handle_input_audio_buffer_speech_started,
      :"input_audio_buffer.speech_stopped" => :handle_input_audio_buffer_speech_stopped,
      :"conversation.item.created" => :handle_conversation_item_created,
      :"conversation.item.input_audio_transcription.completed" => :handle_conversation_item_input_audio_transcription_completed,
      :"conversation.item.input_audio_transcription.failed" => :handle_conversation_item_input_audio_transcription_failed,
      :"conversation.item.truncated" => :handle_conversation_item_truncated,
      :"conversation.item.deleted" => :handle_conversation_item_deleted,
      :"response.created" => :handle_response_created,
      :"response.done" => :handle_response_done,
      :"response.output_item.added" => :handle_response_output_item_added,
      :"response.output_item.done" => :handle_response_output_item_done,
      :"response.content_part.added" => :handle_response_content_part_added,
      :"response.content_part.done" => :handle_response_content_part_done,
      :"response.text.delta" => :handle_response_text_delta,
      :"response.text.done" => :handle_response_text_done,
      :"response.audio_transcript.delta" => :handle_response_audio_transcript_delta,
      :"response.audio_transcript.done" => :handle_response_audio_transcript_done,
      :"response.audio.delta" => :handle_response_audio_delta,
      :"response.audio.done" => :handle_response_audio_done,
      :"response.function_call_arguments.delta" => :handle_response_function_call_arguments_delta,
      :"response.function_call_arguments.done" => :handle_response_function_call_arguments_done,
      :"rate_limits.updated" => :handle_rate_limits_updated
    }
  end

  private

  def setup_event_handlers
    @ws.on(:open) do |_event|
      puts "Connected to OpenAI WebSocket server for session #{@session_id}."
      @connected = true
    end

    @ws.on(:message) do |event|
      message = JSON.parse(event.data)
      handle_message(message)
    end

    @ws.on(:close) do |event|
      puts "Connection closed for session #{@session_id}, code: #{event.code}, reason: #{event.reason}"
      @connected = false
      EM.stop
    end

    @ws.on(:error) do |error|
      puts "WebSocket Error for session #{@session_id}: #{error.message}"
    end
  end

  def setup_response_handlers
    response_handlers.each do |event, handler|
      puts "Setting up response handler for #{event}"
      @ws.on(event, &method(handler))
    end
  end

  def handle_message(message)
    if message["type"] == "input_audio_buffer.speech_started"
      handle_input_audio_buffer_speech_started(message)
    elsif message["type"] == "response.audio.delta"
      broadcast_audio_delta(message["delta"])
    else
      log_message(message)
    end
  end

  def log_message(message)
    puts "Received message for session #{@session_id}: #{message}"
  end

  def send_message(message)
    if @ws && @ws.ready_state == Faye::WebSocket::API::OPEN
      @ws.send(message.to_json)
    else
      puts "WebSocket not ready for session #{@session_id}. Message not sent: #{message}"
    end
  end

  # Server Event Handlers
  def handle_response_error(message)
    puts "Error: #{message}"
  end

  def handle_session_created(message)
    puts "Session Created: #{message}"
  end

  def handle_session_updated(message)
    puts "Session Updated: #{message}"
  end

  def handle_conversation_created(message)
    puts "Conversation Created: #{message}"
  end

  def handle_input_audio_buffer_committed(message)
    puts "Input Audio Buffer Committed: #{message}"
  end

  def handle_input_audio_buffer_cleared(message)
    puts "Input Audio Buffer Cleared: #{message}"
  end

  def handle_input_audio_buffer_speech_started(message)
    puts "Input Audio Buffer Speech Started: #{message}"
    ActionCable.server.broadcast("open_ai_#{@session_id}", {type: "input_audio_buffer.speech_started", message: message})
  end

  def handle_input_audio_buffer_speech_stopped(message)
    puts "Input Audio Buffer Speech Stopped: #{message}"
  end

  def handle_conversation_item_created(message)
    puts "Conversation Item Created: #{message}"
  end

  def handle_conversation_item_input_audio_transcription_completed(message)
    puts "Conversation Item Input Audio Transcription Completed: #{message}"
  end

  def handle_conversation_item_input_audio_transcription_failed(message)
    puts "Conversation Item Input Audio Transcription Failed: #{message}"
  end

  def handle_conversation_item_truncated(message)
    puts "Conversation Item Truncated: #{message}"
  end

  def handle_conversation_item_deleted(message)
    puts "Conversation Item Deleted: #{message}"
  end

  def handle_response_created(message)
    puts "Response Created: #{message}"
  end

  def handle_response_done(message)
    puts "Response Done: #{message}"
  end

  def handle_response_output_item_added(message)
    puts "Response Output Item Added: #{message}"
  end

  def handle_response_output_item_done(message)
    puts "Response Output Item Done: #{message}"
  end

  def handle_response_content_part_added(message)
    puts "Response Content Part Added: #{message}"
  end

  def handle_response_content_part_done(message)
    puts "Response Content Part Done: #{message}"
  end

  def handle_response_text_done(message)
    puts "Response Text Done: #{message}"
  end

  def handle_response_audio_transcript_delta(message)
    puts "Response Audio Transcript Delta: #{message}"
  end

  def handle_response_audio_transcript_done(message)
    puts "Response Audio Transcript Done: #{message}"
  end

  def handle_response_audio_delta(message)
    # puts "Response Audio Delta: #{message}"
    ActionCable.server.broadcast("open_ai_#{@session_id}", {audio_delta: message["delta"]})
  end

  def handle_response_audio_done(message)
    puts "Response Audio Done: #{message}"
  end

  def handle_response_function_call_arguments_delta(message)
    puts "Response Function Call Arguments Delta: #{message}"
  end

  def handle_response_function_call_arguments_done(message)
    puts "Response Function Call Arguments Done: #{message}"
  end

  def handle_rate_limits_updated(message)
    puts "Rate Limits Updated: #{message}"
  end

  def broadcast_audio_delta(delta)
    ActionCable.server.broadcast("open_ai_#{@session_id}", {type: "audio", data: delta})
  end

  # Modify other broadcast methods similarly
  def handle_response_text_delta(message)
    ActionCable.server.broadcast("open_ai_#{@session_id}", {type: "text", data: message})
  end
end
