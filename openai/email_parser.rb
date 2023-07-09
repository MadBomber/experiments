#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: email_parser.rb
##  Desc: parse an email with openAI
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
# See: https://dev.to/kanehooper/creating-an-ai-email-parser-using-ruby-and-openai-gpt-3-1mb4?ck_subscriber_id=791584073
#

require "ruby/openai"
# require "chat_gpt_error_handler" # For Rails

require 'debug_me'
include DebugMe

require 'amazing_print'
require 'nenv'
require 'mail'
require 'date'          # STDLIB


Mail.defaults do
  retriever_method :imap, address:    "imap.gmail.com",
                          port:       993,
                          user_name:  Nenv.gmail_user,
                          password:   Nenv.gmail_pass,
                          enable_ssl: true
end

AI = OpenAI::Client.new(access_token: Nenv.openai_api_key)

######################################################
# Local methods

def extract_entities(email)
  prompt = "Extract the company names, email sender's name, and theme of the following email:\n\n#{email}"
  send_prompt prompt
end

def send_prompt(prompt)
 response = AI.completions(
   parameters: {
     model: "text-davinci-003",
     prompt: prompt,
     temperature: 0.5,
     max_tokens: 1000
   }
 )

 response['choices'][0]['text']
end



def get_email_text(username, password)
  gmail = Gmail.connect(username, password)
  email = gmail.inbox.emails.first
  text = email.body.decoded
  gmail.logout
  return text
end

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


begin

puts "Retrieving eMails ..."
emails = Array(
            Mail.find( what:   :last,
                    count:  14,      # how many days back from today
                    order:  :asc,
                    keys:   'FROM newsletters@analystratings.net')
          )


debug_me{[
  :emails
]}

rescue => error_message
  puts "ERROR: #{error_message}"
  puts
  puts "Looking up possible causes and solutions ..."
  puts 
  
  # TODO: Add an "I'm working spinner"

  prompt = <<~EOS
    A Ruby program has terminated with an error.
    Clearly list possible reasons and a solution.
    Your answer will be displayed in the terminal.
    Do NOT repeat the error message back verbatim.
    Here is the error message: '#{error_message}'. 
    Possible reason or solution?"
  EOS

  puts send_prompt prompt

end
__END__

answer = extract_entities email


puts answer
