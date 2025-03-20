# money.rb
require 'bigdecimal'

class Money
  include Comparable
  attr_reader :cents

  def initialize(amount)
    # Convert to BigDecimal for exact precision
    bd_amount = BigDecimal(amount.to_s)
    @cents = (bd_amount * 100).to_i # No rounding, just truncate after multiplication
    # Debug output to verify
    puts "DEBUG: amount=#{amount}, bd_amount=#{bd_amount.to_s('F')}, cents=#{@cents}"
  end

  def self.new(amount)
    super(amount)
  end

  def +(other)
    other_cents = other.is_a?(Money) ? other.cents : (BigDecimal(other.to_s) * 100).to_i
    Money.new((cents + other_cents) / 100.0)
  end

  def -(other)
    other_cents = other.is_a?(Money) ? other.cents : (BigDecimal(other.to_s) * 100).to_i
    Money.new((cents - other_cents) / 100.0)
  end

  def *(other)
    other_value = other.is_a?(Money) ? (other.cents / 100.0) : other.to_f
    Money.new((cents * other_value) / 100.0)
  end

  def /(other)
    other_value = other.is_a?(Money) ? (other.cents / 100.0) : other.to_f
    Money.new((cents / other_value) / 100.0)
  end

  def %(other)
    other_cents = other.is_a?(Money) ? other.cents : (BigDecimal(other.to_s) * 100).to_i
    Money.new((cents % other_cents) / 100.0)
  end

  def to_s
    absolute_cents = cents.abs
    dollars = absolute_cents / 100 # Integer division on absolute value
    cents_remainder = (absolute_cents % 100).to_s.rjust(2, '0')
    whole = dollars.to_s
    whole_with_commas = whole.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    formatted = "$#{whole_with_commas}.#{cents_remainder}"
    cents.negative? ? "(#{formatted})" : formatted
  end

  def inspect
    "Money(#{cents / 100.0})"
  end

  def ==(other)
    other.is_a?(Money) && cents == other.cents
  end

  def <=>(other)
    return nil unless other.is_a?(Money)
    cents <=> other.cents
  end
end

class Integer
  def to_money
    Money.new(self)
  end
end

def Money(amount)
  Money.new(amount)
end
