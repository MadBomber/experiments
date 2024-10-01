#!/usr/bin/env ruby
# experiments/OmniAI/ai_client/examples/transcribe.rb

require_relative 'common'

box "Bethany Hamilton on Facing Fear"

audio_file = 'Bethany Hamilton.m4a'  # Poor volume level

models = [
  'whisper-1',           # OpenAI
  # 'deepgram-nova-2'      # Deepgram (if supported)
]
clients = []

models.each do |model|
  clients << AiClient.new(model)
end

title "Default Configuration Speech-to-Text"


clients.each do |c|
  puts "\nModel: #{c.model} (#{c.model_type})  Provider: #{c.provider}"
  result = c.transcribe(audio_file)
  puts "Transcription: #{result.pretty_inspect}"
end

__END__

Tucker Carlson: How do you deal with fear? 

Bethany Hamilton: Okay, so I deal with fear maybe more naturally and
better than your average human, but I would say It's not like a really
thoughtful process for me. It's truly just facing my fears and not letting my
fears like over take me so much that I get paralyzed. So I think maybe since
I, you know, when I lost my arm when I was 13 years old. I had such a deep
passion for surfing that my decision to get back in the ocean was based off
of like getting back to my passion and my love for riding waves and not just
facing my fears, you know, I had like a deeper reason like I just love doing
what I did. And so I wanted to see if it was possible with one arm. So I
truly just faced my fears and over time, I think facing them over and over
and over again. I eventually became less fearful of sharks, so to say. And
it's funny, I've heard that sharks and motivational speaking are like
people's two greatest fears. That's like the two things that I do I surf with
sharks in the ocean, or like, you know, overcome my like incident with the
shark and then I do motivational speaking, which I would say I didn't like
that at first. But eventually I overcame that like that dislike or that fear
or that uncomfortability and I think so often in life where we naturally want
to like run from discomfort, you know, we want to make things as easy and
comfortable as possible. And so if you can learn to recognize that sometimes
you can't do that and sometimes you have to like walk into uncomfortable, you
know, I find them like relationships, for example, sometimes you have to have
the uncomfortable conversations to make that relationship more beautiful. But
a lot of us just want to like avoid that instead. And in the long run, that
just makes the relationship less beautiful and less meaningful and less
filled with depth, and then eventually that relationship may dissipate.

Tucker Carlson: Absolutely right.
