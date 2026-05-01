#!/usr/bin/env ruby
# experiments/ai_misc/lm_studio_demo.rb
#
# Demo: Using RubyLLM with LM Studio's OpenAI-compatible API.
#
# Three implementations:
#   1. RubyLLM  (default) - uses RubyLLM's built-in model listing and chat
#   2. Net::HTTP (--raw)  - raw HTTP for model discovery, RubyLLM for chat
#   3. RobotLab (--robot) - uses RobotLab.build for agent-style interaction
#
# Prerequisites:
#   - LM Studio running locally with a model loaded
#   - LMS_BASE_URL env var set (e.g. http://localhost:1234/v1)
#
# Usage:
#   ruby lm_studio_demo.rb [--raw | --robot] [--model model_name]
#
# Flags:
#   --raw              Use Net::HTTP for model discovery, RubyLLM for chat
#   --robot            Use the RobotLab library for the full workflow
#   --model MODEL      Specify the model name (otherwise auto-detected)
#
# If no model_name is given, it queries LM Studio for loaded models.

require "ruby_llm"
require "debug_me"
include DebugMe

USE_RAW   = ARGV.delete("--raw")
USE_ROBOT = ARGV.delete("--robot")

model_idx = ARGV.index("--model")
EXPLICIT_MODEL = if model_idx
                   ARGV.delete_at(model_idx) # remove --model
                   ARGV.delete_at(model_idx) # remove the value
                 else
                   ARGV.shift # positional model name, if any
                 end

require "robot_lab" if USE_ROBOT
base_url = ENV.fetch("LMS_BASE_URL") do
  abort "Error: LMS_BASE_URL environment variable is not set.\n" \
        "  export LMS_BASE_URL=http://localhost:1234/v1"
end

RubyLLM.configure do |config|
  config.openai_api_key  = "lm-studio"  # LM Studio ignores this but RubyLLM requires it
  config.openai_api_base = base_url
end

def discover_models_raw(base_url)
  require "net/http"
  require "json"

  uri = URI("#{base_url}/models")

  begin
    response = Net::HTTP.get_response(uri)
  rescue Errno::ECONNREFUSED
    abort "Cannot connect to LM Studio at #{base_url}\n" \
          "  Is LM Studio running with a model loaded?"
  rescue SocketError => e
    abort "Network error reaching LM Studio: #{e.message}"
  end

  unless response.is_a?(Net::HTTPSuccess)
    abort "Could not reach LM Studio at #{base_url}/models (#{response.code})"
  end

  models = JSON.parse(response.body).dig("data")&.map { |m| m["id"] } || []
  abort "No models loaded in LM Studio. Load a model first." if models.empty?

  debug_me { :models }
  models
end

def discover_models_ruby_llm
  RubyLLM.models.refresh!
  models = RubyLLM.models.by_provider(:openai).map(&:id)
  abort "No models loaded in LM Studio. Load a model first." if models.empty?

  debug_me { :models }
  models
rescue Faraday::ConnectionFailed
  abort "Cannot connect to LM Studio at #{RubyLLM.config.openai_api_base}\n" \
        "  Is LM Studio running with a model loaded?"
rescue StandardError => e
  abort "Error discovering models: #{e.message}"
end

def discover_models_robot_lab
  RubyLLM.models.refresh!
  models = RubyLLM.models.by_provider(:openai).map(&:id)
  abort "No models loaded in LM Studio. Load a model first." if models.empty?

  debug_me { :models }
  models
rescue Faraday::ConnectionFailed
  abort "Cannot connect to LM Studio at #{RubyLLM.config.openai_api_base}\n" \
        "  Is LM Studio running with a model loaded?"
rescue StandardError => e
  abort "Error discovering models: #{e.message}"
end

model_name = EXPLICIT_MODEL

unless model_name
  impl = if USE_RAW then "Net::HTTP"
         elsif USE_ROBOT then "RobotLab"
         else "RubyLLM"
         end
  debug_me "Discovering models via #{impl}"

  models = if USE_RAW
             discover_models_raw(base_url)
           elsif USE_ROBOT
             discover_models_robot_lab
           else
             discover_models_ruby_llm
           end

  model_name = models.first
end

# When a model was given explicitly, the registry hasn't been refreshed yet.
# RobotLab.build calls RubyLLM.chat internally without assume_model_exists,
# so we need the model in the registry before building.
if EXPLICIT_MODEL && USE_ROBOT
  RubyLLM.models.refresh!
end

mode_label = if USE_RAW then "raw (Net::HTTP)"
             elsif USE_ROBOT then "robot_lab"
             else "ruby_llm"
             end

puts <<~BANNER
  LM Studio Demo
  Model:    #{model_name}
  Endpoint: #{base_url}
  Mode:     #{mode_label}
  Type 'exit' to quit.

BANNER

if USE_ROBOT
  robot = RobotLab.build(
    name:          "lm_studio_assistant",
    system_prompt: "You are a helpful assistant running locally via LM Studio.",
    model:         model_name
  )
  robot.chat.with_model(model_name, provider: :openai, assume_exists: true)

  loop do
    print "> "
    user_input = $stdin.gets&.chomp
    break if user_input.nil? || user_input.strip.downcase == "exit"
    next  if user_input.strip.empty?

    result = robot.run(user_input)
    result.output.each do |message|
      puts "\n#{message.content}\n\n" if message.respond_to?(:content)
    end
  end
else
  chat = RubyLLM.chat(
    model:              model_name,
    provider:           :openai,
    assume_model_exists: true
  )

  chat.with_instructions("You are a helpful assistant running locally via LM Studio.")

  loop do
    print "> "
    user_input = $stdin.gets&.chomp
    break if user_input.nil? || user_input.strip.downcase == "exit"
    next  if user_input.strip.empty?

    response = chat.ask(user_input)
    puts "\n#{response.content}\n\n"
  end
end

puts "Goodbye!"
