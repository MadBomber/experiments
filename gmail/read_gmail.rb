#!/usr/bin/env ruby
# read_gmail.rb
#
# Reads unread Gmail messages via IMAP using an App Password.
#
# Setup:
#   1. Enable 2-Factor Authentication on your Google account
#   2. Go to myaccount.google.com/apppasswords
#   3. Generate an App Password for "Mail"
#   4. Set environment variables:
#        export GMAIL_ADDRESS="you@gmail.com"
#        export GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx"
#   5. Ensure IMAP is enabled in Gmail Settings > Forwarding and POP/IMAP
#
# Dependencies:
#   gem install mail
#
# Usage:
#   ruby read_gmail.rb

require_relative 'gmail_reader'

gmail = GmailReader.new

puts "Unread messages: #{gmail.count}"

# Fetch the newest unread message
msg = gmail.first

if msg.nil?
  puts "No unread messages found."
  exit
end

puts msg

if msg.multipart?
  puts "Multipart message with #{msg.parts.length} part(s)"
  puts

  msg.parts.each_with_index do |part, i|
    ct = part.content_type.split(';').first

    if ct == 'text/plain'
      puts "--- Part #{i}: text/plain ---"
      puts part.decoded
      puts
    elsif ct == 'text/html'
      puts "--- Part #{i}: text/html (#{part.decoded.length} bytes) ---"
      puts
    elsif ct.start_with?('multipart/')
      part.parts.each_with_index do |subpart, j|
        sub_ct = subpart.content_type.split(';').first
        puts "--- Part #{i}.#{j}: #{sub_ct} ---"
        if sub_ct.start_with?('text/')
          puts subpart.decoded
        else
          puts "(binary content, #{subpart.decoded.length} bytes)"
        end
        puts
      end
    else
      filename = part.filename || "(unnamed)"
      puts <<~HEREDOC
        --- Part #{i}: Attachment ---
          Filename:     #{filename}
          Content-Type: #{ct}
          Size:         #{part.decoded.length} bytes
      HEREDOC
    end
  end
else
  ct = msg.body.content_type&.split(';')&.first || 'text/plain'
  puts "--- Body (#{ct}) ---"
  puts msg.text_plain
  puts
end

if msg.attachments.any?
  puts "#{msg.attachments.length} attachment(s):"
  msg.attachments.each do |att|
    puts "  - #{att.filename} (#{att.mime_type}, #{att.decoded.length} bytes)"
  end
end
