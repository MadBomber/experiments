#!/usr/bin/env ruby
# experiments/peer2peer/one_time_pad.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

class OneTimePad
  attr_reader :result

  def initialize(
      dt:,            # required
      message:,       # required
      action:   :code # or :decode
    )

    @otp = generate_otp(dt:, max_rows: message.size)

    @result = {
      dt:,
      message: process_message(message:, action:),
    }
  end

  # Generates a random seed based on provided UTC time
  #
  # @return [Integer] A random seed value
  def kaos(dt)
    utc = dt.utc
    utc.year + utc.month + utc.day +
    utc.hour + utc.min   + utc.sec +
    utc.usec
  end

  # Generates a @otp of shuffled ASCII codes
  #
  # @param max_rows [Integer] The maximum number of rows
  # @return [Array<Array<Integer>>] A 2D array of shuffled
  #   ASCII codes
  def generate_otp(dt:, max_rows:)
    srand(kaos(dt)) # seed the random generator
    ascii_codes = (32..126).to_a
    row_size    = ascii_codes.size
    Array.new(max_rows) { ascii_codes.shuffle }
  end


  # Processes the message based on the action
  #
  # @param message [String, Array<Integer>] The message to process
  # @param action [Symbol] The action to perform (:code or :decode)
  # @return [Array<Integer>, String] The processed message
  def process_message(message:, action:)
    case action
    when :code
      code(message:)
    when :decode
      decode(message:)
    end
  end

  # Encodes a message using the provided @otp
  #
  # @param @otp [Array<Array<Integer>>] The encoding @otp
  # @param message [String] The message to encode
  # @return [Array<Integer>] The encoded message as an array
  #   of integers
  def code(message:)
    ascii_string = message.encode('ASCII', 
                                  invalid: :replace,
                                  undef:   :replace, 
                                  replace: '_')

    ascii_string.bytes.map.with_index do |byte, i|
      row       = @otp[i % @otp.size]
      char_code = byte.clamp(32, 126)
      row[char_code - 32]
    end
  end

  # Decodes a message using the provided @otp
  #
  # @param @otp [Array<Array<Integer>>] The decoding @otp
  # @param coded_message [Array<Integer>, String] The encoded
  #   message
  # @return [String] The decoded message
  def decode(message:)
    encoded = message.is_a?(String) ? message.bytes : message
    encoded.map.with_index do |code, i|
      row        = @otp[i % @otp.size]
      char_index = row.index(code)
      if char_index.nil?
        '_'
      else
        (char_index + 32).chr
      end
    end.join
  end
end

# Main Line
if __FILE__ == $PROGRAM_NAME

  original_message = <<~MESSAGE
    The British are comming!
    The British are comming!
    The British are comming!
    The British are comming!
    They are so pretty in their red coats; however,
    its our job as minute men to shoot them
    down.  Don't fire until you see the whites of their eyes!
    Grab your muskets and hide your women!
    Grab your muskets and hide your women!
    Grab your muskets and hide your women!
    Grab your muskets and hide your women!
    The British are comming!
    The British are comming!
  MESSAGE

  now = Time.now

  otp = OneTimePad.new(dt: now, message: original_message, action: :code)

  puts
  puts otp.result[:message].map{|o| o.chr}.join

  puts "="*65

  otp = OneTimePad.new(dt: now, message: otp.result[:message], action: :decode)

  puts otp.result[:message]
  puts
end
