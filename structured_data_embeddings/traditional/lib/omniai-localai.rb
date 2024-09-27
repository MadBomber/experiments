# omniai-localai.rb
# frozen_string_literal: true

require 'omniai'
require 'omniai/openai'

module OmniAI

  # Create an alias for OmniAI::OpenAI module
  module LocalAI
    extend OmniAI::OpenAI

    # Alias classes from OmniAI::OpenAI
    class Client < OmniAI::OpenAI::Client
      def initialize(**options)
        options[:host] = 'http://localhost:8080' unless options.has_key?(:host)
        super(**options)
      end
    end


    Config = OmniAI::OpenAI::Config

    # Alias the Thread class and its nested classes
    Thread      = OmniAI::OpenAI::Thread
    Annotation  = OmniAI::OpenAI::Thread::Annotation
    Attachment  = OmniAI::OpenAI::Thread::Attachment
    Message     = OmniAI::OpenAI::Thread::Message
    Run         = OmniAI::OpenAI::Thread::Run
  end
end
