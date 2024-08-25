#!/usr/bin/env ruby
# experiments/OmniAI/examples/transcribe.rb

require_relative 'common'

box "transcribe Example is TBD"

__END__

models = [
  'whisper-1',           # OpenAI
  'google-speech-v1',    # Google (placeholder, adjust as needed)
  'deepgram-nova-2'      # Deepgram (if supported)
]
clients = []

models.each do |model|
  clients << MyClient.new(model)
end

title "Default Configuration Speech-to-Text"

audio_file = 'path/to/your/audio/file.mp3'  # Replace with actual path

clients.each do |c|
  puts "\nModel: #{c.model} (#{c.model_type})  Provider: #{c.provider}"
  result = c.transcribe(audio_file)
  puts "Transcription: #{result}"
end
