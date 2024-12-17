#!/usr/bin/env ruby
# experiments/peer2peer/code_decode.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

message = <<~MESSAGE
  The British are comming!
  The British are comming!
  They are so pretty in their red coats; however,
  its our job as minute men to shoot them
  down.  Don't fire until you see the whites of their eyes!
MESSAGE

# message = 'Hello World'

# Generates a random seed based on current UTC time
#
# @return [Integer] A random seed value
def kaos
  now = Time.now.utc
  now.year + now.month + now.day + now.hour + now.min + now.sec + now.usec
end


# Generates a matrix of shuffled ASCII codes
#
# @param max_rows [Integer] The maximum number of rows in the matrix
# @return [Array<Array<Integer>>] A 2D array of shuffled ASCII codes
def generate_matrix(max_rows:)
  ascii_codes = (32..126).to_a
  row_size    = ascii_codes.size
  Array.new(max_rows) { ascii_codes.shuffle }
end



# Encodes a message using the provided matrix
#
# @param matrix [Array<Array<Integer>>] The encoding matrix
# @param message [String] The message to encode
# @return [Array<Integer>] The encoded message as an array of integers
def code_message(matrix:, message: 'Hello World')
  ascii_string = message.encode('ASCII', invalid: :replace,
                                undef:   :replace, replace: '_')

  ascii_string.bytes.map.with_index do |byte, i|
    row       = matrix[i % matrix.size]
    char_code = byte.clamp(32, 126)
    row[char_code - 32]
  end
end

# Decodes a message using the provided matrix
#
# @param matrix [Array<Array<Integer>>] The decoding matrix
# @param coded_message [Array<Integer>, String] The encoded message
# @return [String] The decoded message
def decode_message(matrix:, coded_message:)
  encoded = coded_message.is_a?(String) ? coded_message.bytes : coded_message
  encoded.map.with_index do |code, i|
    row        = matrix[i % matrix.size]
    char_index = row.index(code)
    if char_index.nil?
      '_'
    else
      (char_index + 32).chr
    end
  end.join
end

##############################
## Main Line

# Set the random seed
srand(kaos)

# build the one time pad based upon the message
# to send

otp = generate_matrix(max_rows: message.size)

# Code the message

secret_message = code_message(matrix: otp, message: message)

puts secret_message.map{|c| c.chr}.join
puts "================"

# Decode the message

original_message = decode_message(matrix: otp, coded_message: secret_message)

puts original_message

