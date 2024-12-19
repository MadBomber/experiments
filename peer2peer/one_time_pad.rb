#!/usr/bin/env ruby
# experiments/peer2peer/one_time_pad.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

class OneTimePad
  MAX_ROWS = 2048

  attr_accessor :pad, :secret

  def initialize(
      secret: nil,
      otp:    nil
    )

    @secret = secret

    if otp
      @pad = otp
    end
  end

  # Generates a random seed based on provided UTC time
  #
  # @return [Integer] A random seed value
  def kaos
    utc = secret.nil? ? Time.now.utc : secret
    utc.year + utc.month + utc.day +
    utc.hour + utc.min   + utc.sec +
    utc.usec
  end

  # Generates a @pad of shuffled ASCII codes
  #
  # @param max_rows [Integer] The maximum number of rows
  # @return [Array<Array<Integer>>] A 2D array of shuffled
  #   ASCII codes
  def generate_otp
    srand(kaos) # seed the random generator
    ascii_codes = (32..126).to_a
    row_size    = ascii_codes.size
    @pad = Array.new(MAX_ROWS) { ascii_codes.shuffle }
  end


  # Encodes a message using the provided @pad
  #
  # @param @pad [Array<Array<Integer>>] The encoding @pad
  # @param message [String] The message to encode
  # @return [Array<Integer>] The encoded message as an array
  #   of integers
  def code(message:)
    ascii_string = message.encode('ASCII', 
                                  invalid: :replace,
                                  undef:   :replace, 
                                  replace: '_')

    ascii_string.bytes.map.with_index do |byte, i|
      row       = @pad[i % @pad.size]
      char_code = byte.clamp(32, 126)
      row[char_code - 32]
    end.map(&:chr).join
  end

  # Decodes a message using the provided @oad
  #
  # @param @otp [Array<Array<Integer>>] The decoding @otp
  # @param coded_message [Array<Integer>, String] The encoded
  #   message
  # @return [String] The decoded message
  def decode(message:)
    encoded = message.is_a?(String) ? message.bytes : message
    encoded.map.with_index do |code, i|
      row        = @pad[i % @pad.size]
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

  otp         = OneTimePad.new
  otp.secret  = Time.now
  my_code     = otp.generate_otp
  secret      = otp.code(message: original_message)

  puts
  puts secret
  puts "="*65
  puts otp.decode(message: secret)
  puts "="*65
  puts "== Different Instance with otp passed in ..."
  puts
  another = OneTimePad.new(otp: my_code)
  puts another.decode(message: secret)
  puts
end
