# omniai-ollama.rb
# frozen_string_literal: true
#
# This is an experimental ruby library in its
# pre-gem state.  It is in the process of being
# developed as an extension of the OmniAI gem.
# It is Open Source.
#
# The purpose of this library is to allow access
# to a running instance of the Ollama server.
# The API for Ollama is the same as OpenAI.
# This library makes use of that knowledge to
# constructure an OmniAI::Ollama namespace on
# top of the existing OmniAI::OpenAI namespace.


require 'omniai'
require 'omniai/openai'

module OmniAI

  # Create an alias for OmniAI::OpenAI module
  module Ollama
    extend OmniAI::OpenAI

    # Alias classes from OmniAI::OpenAI
    class Client < OmniAI::OpenAI::Client
      def initialize(**options)
        options[:host] = 'http://localhost:11434' unless options.has_key?(:host)
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
