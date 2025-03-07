# segmented_display.rb

require 'amazing_print'

# parse and generate 3x3 segmented display of digits
#
class SegmentedDisplay
  SEGMENTS = {
    " _ | ||_|" => "0",  #  _
                         # | |
                         # |_|
    "     |  |" => "1",  #
                         #   |
                         #   |
    " _  _||_ " => "2",  #  _
                         #  _|
                         # |_
    " _  _| _|" => "3",  #  _
                         #  _|
                         #  _|
    "   |_|  |" => "4",  #
                         # |_|
                         #   |
    " _ |_  _|" => "5",  #  _
                         # |_
                         #  _|
    " _ |_ |_|" => "6",  #  _
                         # |_
                         # |_|
    " _   |  |" => "7",  #  _
                         #   |
                         #   |
    " _ |_||_|" => "8",  #  _
                         # |_|
                         # |_|
    " _ |_| _|" => "9",  #  _
                         # |_|
                         #  _|
  }

  REVERSE_SEGMENTS = SEGMENTS.invert

  MUTATIONS = {}

  def self.mutate
    SEGMENTS.each do |segment, digit|
      MUTATIONS[digit.to_i] = []
      9.times do |i|
        mutated_segment = segment.dup
        # Add a pipe or remove either a pipe or an underscore
        mutated_segment[i] = mutated_segment[i] == ' ' ? '|' : ' '
        if SEGMENTS.key?(mutated_segment)
          mutant = SEGMENTS[mutated_segment].to_i
          MUTATIONS[digit.to_i] << mutant unless MUTATIONS[digit.to_i].include?(mutant)
        end

        mutated_segment = segment.dup
        # Add an underscore or remove either a pipe or an underscore
        # This may result in duplicate digits
        mutated_segment[i] = mutated_segment[i] == ' ' ? '_' : ' '
        if SEGMENTS.key?(mutated_segment)
          mutant = SEGMENTS[mutated_segment].to_i
          MUTATIONS[digit.to_i] << mutant unless MUTATIONS[digit.to_i].include?(mutant)
        end
      end
    end

    ap MUTATIONS.transform_values(&:uniq)
  end


  def self.parse(input)
    lines   = input.split("\n").reject(&:empty?)
    digits  = []
    result  = ""

    num_of_digits = lines[0].size / 3

    (0...num_of_digits).each do |digit_index|
      segment = ""
      (0...3).each do |line_index|
        segment << lines[line_index][digit_index * 3, 3]
      end
      digits << (SEGMENTS[segment] || "?")
    end

    result = digits.join

    if !result.include?("?") && result.length == 9 && valid_checksum?(result)
      result
    else
      "Invalid"
    end
  end

  def self.convert(input)
    digits = input.to_s.chars
    lines  = Array.new(3) { "" }

    digits.each do |digit|
      segment = REVERSE_SEGMENTS[digit]
      lines[0] << segment[0..2]
      lines[1] << segment[3..5]
      lines[2] << segment[6..8]
    end

    lines.join("\n")
  end

  # Validate the checksum of a 9-digit number
  # Formula: (d1+(2*d2)+(3*d3)+...+(9*d9)) mod 11 = 0
  # where d1 is the least significant digit and d9 is
  # the most significant digit
  def self.valid_checksum?(number)
    return false unless number.match?(/^\d{9}$/)

    sum = number.reverse.chars.map.with_index do |digit, index|
      digit.to_i * (index + 1)
    end.sum

    (sum % 11).zero?
  end
end

# Example usage:
input = <<~DIGITS
  _  _     _  _  _  _  _
 | || |  | _| _||_||_ |_
 |_||_|  | _|  |  ||_| _|
DIGITS

puts SegmentedDisplay.parse(input)  # Output: "012345678" or "Invalid"

puts SegmentedDisplay.convert("567890123")
puts SegmentedDisplay.convert(1234567890)
SegmentedDisplay.mutate
