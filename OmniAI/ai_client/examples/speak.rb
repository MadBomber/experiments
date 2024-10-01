#!/usr/bin/env ruby
# experiments/OmniAI/ai_client/examples/speak.rb

$player = "afplay" # For MacOS

require_relative 'common'

def play(audio_file)
  `#{$player} #{audio_file}`
end


models = [
  'tts-1',               # OpenAI
  # 'google-tts-1',        # Google (placeholder, adjust as needed)
  # 'elevenlabs-v1'        # ElevenLabs (if supported)
]
clients = []

models.each do |model|
  clients << AiClient.new(model)
end

title "Default Configuration Text-to-Speech"

clients.each do |c|
  puts "\nModel: #{c.model} (#{c.model_type})  Provider: #{c.provider}"
  text = "Text to speach example using the #{c.model} by provider #{c.provider} with the default voice."
  result = c.speak(text)
  puts "Audio generated. Tempfile: #{result.path}"
  play result.path
end
