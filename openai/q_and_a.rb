#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: q_and_a.rb
##  Desc: Using OpenAI in a Q&A REPL
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require "ruby/openai"

require "nenv"          # Convenience wrapper for Ruby's ENV
require "reline"        # Alternative GNU Readline or Editline implementation by pure Ruby.
require "tty-box"       # Draw various frames and boxes in the terminal window.
require 'tty-spinner'   # A terminal spinner for tasks that have non-deterministic time frame.
require 'word_wrap'     # Simple tool for word-wrapping text


at_exit do
  puts
  puts "Done."
  puts
end


AI = OpenAI::Client.new(access_token: Nenv.openai_api_key)

def answer(text)
  spinner = TTY::Spinner.new("      [:spinner] Thinking ...", format: :pulse_2)

  spinner.auto_spin # Automatic animation with default interval

  response = 
    AI.completions(
      parameters: {
        model:      "text-davinci-003",
        prompt:     text,
        max_tokens: 2000
      }
    )

  spinner.stop("Got it!") # Stop animation

  response['choices'][0]['text']
end


Reline.prompt_proc = proc { |lines|
  lines.each_with_index.map { |l, i|
    '[%04d] Q? ' % i
  }
}

def question
  question_prompt = 'Q? '
  use_history     = true

  puts "Enter 'send' when ready for answer."

  text = Reline.readmultiline(question_prompt, use_history) do |multiline_input|
    multiline_input.split.last == "send"
  end

  text.chomp.strip.gsub("\n", " ").gsub(/ send$/,'').squeeze(" ")
end

##########################################
## Main ... REPL

begin
  while true do
    text = question

    puts "You asked:"
    puts TTY::Box.frame(WordWrap.ww(text))

    text = answer(text)

    puts WordWrap.ww(text)
    puts 
    puts "Cntl-C to terminate"
    puts 
  end

rescue Interrupt
  puts "^C"
  exit(0)
end

