#!/usr/bin/env ruby
# frozen_string_literal: true

require "readline"
require_relative "lib/finn"

BANNER = <<~BANNER
  +---------------------------------------------------+
  |   Finn  --  AI Finance Analyst                    |
  |   Powered by Claude + Yahoo Finance               |
  |   Type 'exit', 'quit', or Ctrl+D to quit         |
  |   Type 'reset' to start a new conversation       |
  +---------------------------------------------------+
BANNER

puts BANNER

unless ENV["ANTHROPIC_API_KEY"] || ENV["OPENAI_API_KEY"]
  warn "Warning: No API key found. Set ANTHROPIC_API_KEY or OPENAI_API_KEY in .env"
  exit 1
end

model = ENV.fetch("FINN_MODEL", "claude-sonnet-4-6")
puts "Using model: #{model}\n\n"

begin
  agent = Finn::Agent.new(model: model)
rescue => e
  warn "Failed to initialize Finn: #{e.message}"
  exit 1
end

Readline.completion_proc = proc { |_| [] }

loop do
  raw = Readline.readline("You: ", true)

  if raw.nil?
    puts "\nGoodbye!"
    break
  end

  input = raw.strip
  next if input.empty?

  case input.downcase
  when "exit", "quit", "bye"
    puts "\nGoodbye!"
    break
  when "reset"
    agent.reset
    puts "[New conversation started]\n"
    next
  end

  print "\nFinn: "
  $stdout.flush

  begin
    response = agent.ask(input)
    puts response.content
    puts
  rescue Interrupt
    puts "\n[Interrupted]"
    break
  rescue => e
    puts "\nError: #{e.message}"
  end
end
