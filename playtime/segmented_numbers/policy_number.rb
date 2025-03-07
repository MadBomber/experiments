# policy_number.rb

require_relative 'segmented_display'

class PolicyNumber
  attr_reader :segmented, :number, :status

  def initialize(segmented)
    @segmented = segmented
    @number    = SegementedDisplay.parse(segmented).to_s
    @status    = validate
  end

  def validate
    if !@number.include?("?")
      "ILL"
    elsif !valid_checksum?
      "ERR"
    else
      ""
    end
  end

  def valid_checksum?
    sum = @number.reverse.chars.map.with_index do |digit, index|
      digit.to_i * (index + 1)
    end.sum

    (sum % 11).zero?
  end

  def to_s
    "#{number} #{status}"
  end
end
