---
name: rubyllm-audio-transcription
description: |
  Convert speech to text with RubyLLM. Use this skill for transcribing meetings, podcasts, lectures, interviews with support for speaker diarization, timestamps, and multiple languages.
---

# RubyLLM Audio Transcription

Convert speech to text with support for multiple languages and speaker diarization.

**v1.9.0+**

## Basic Usage

```ruby
# Basic transcription
transcription = RubyLLM.transcribe("meeting.wav")
puts transcription.text

# With specific model
transcription = RubyLLM.transcribe("audio.mp3", model: 'whisper-1')

# Access metadata
puts "Model: #{transcription.model}"
puts "Duration: #{transcription.duration}s"
puts "Language: #{transcription.language}"
```

## Models

| Model | Provider | Price/min | Best For |
|-------|----------|-----------|----------|
| whisper-1 | OpenAI | $0.006 | General use |
| gpt-4o-transcribe | OpenAI | Varies | Technical content |
| gpt-4o-mini-transcribe | OpenAI | Varies | Fast, cheap |
| gemini-2.5-flash | Google | Varies | Long audio |

```ruby
# Whisper-1 (default)
RubyLLM.transcribe("audio.mp3", model: 'whisper-1')

# GPT-4o Transcribe (technical)
RubyLLM.transcribe("audio.mp3", model: 'gpt-4o-transcribe')

# GPT-4o Mini (fastest)
RubyLLM.transcribe("audio.mp3", model: 'gpt-4o-mini-transcribe')

# Diarization (speaker identification)
RubyLLM.transcribe("meeting.wav", model: 'gpt-4o-transcribe-diarize')
```

## Speaker Diarization

Identify different speakers:

```ruby
transcription = RubyLLM.transcribe(
  "meeting.wav",
  model: 'gpt-4o-transcribe-diarize'
)

transcription.speakers.each do |speaker|
  puts "Speaker #{speaker.id}:"
  puts speaker.text
  puts
end
```

## Timestamps & Segments

```ruby
transcription = RubyLLM.transcribe("meeting.wav")

transcription.segments.each do |segment|
  puts "#{format_time(segment.start)} - #{format_time(segment.end)}"
  puts "  #{segment.text}"
  puts "  Speaker: #{segment.speaker_id}" if segment.speaker_id
end

def format_time(seconds)
  mins = (seconds / 60).to_i
  secs = (seconds % 60).to_i
  format("%02d:%02d", mins, secs)
end
```

## Language Options

```ruby
# Language hint (improves accuracy)
RubyLLM.transcribe("audio.mp3", language: 'en')

# Multiple languages
RubyLLM.transcribe("interview.mp3", language: 'es')

# Auto-detect (default)
RubyLLM.transcribe("audio.mp3")
```

## Prompts

Provide context for better accuracy:

```ruby
RubyLLM.transcribe(
  "technical-meeting.wav",
  prompt: 'This is a technical meeting about Ruby on Rails development'
)

RubyLLM.transcribe(
  "medical-lecture.wav",
  prompt: 'Medical terminology, cardiology lecture'
)
```

## Supported Formats

MP3, M4A, WAV, WebM, OGG, FLAC

## Chat with Audio

```ruby
chat = RubyLLM.chat(model: 'gpt-4o-audio-preview')

# Transcribe
chat.ask "Transcribe this", with: 'meeting.mp3'

# Ask follow-up questions
chat.ask "What action items were discussed?"
chat.ask "Who said they would complete the feature by Friday?"
```

## Rails Integration

```ruby
class Meeting < ApplicationRecord
  has_one_attached :recording
  has_one_attached :transcript
  
  after_commit :transcribe, if: :recording_attached?
  
  private
  
  def transcribe
    TranscriptionJob.perform_later(self.id)
  end
end

class TranscriptionJob < ApplicationJob
  def perform(meeting_id)
    meeting = Meeting.find(meeting_id)
    
    # Download attachment
    file = meeting.recording.download
    Tempfile.create(['recording', '.mp3']) do |temp|
      temp.write(file)
      temp.rewind
      
      # Transcribe
      transcription = RubyLLM.transcribe(temp.path)
      
      # Save transcript
      meeting.transcript.attach(
        io: StringIO.new(transcription.text),
        filename: "transcript.txt",
        content_type: 'text/plain'
      )
      
      # Save segments as JSON
      meeting.update!(
        transcription_data: {
          segments: transcription.segments.map(&:to_h),
          speakers: transcription.speakers&.map(&:to_h),
          duration: transcription.duration,
          language: transcription.language
        }
      )
    end
  end
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Multi-Modal**: Using audio in chat conversations
