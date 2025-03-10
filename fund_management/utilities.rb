# fund_management/utilities.rb

class Float
  # Converts a float to a money string with dollar sign,
  # commas, and two decimal places. Negative numbers are
  # enclosed in parentheses.
  def to_money
    whole, decimal = self.abs.to_s.split(".")
    whole_with_commas = whole.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    decimal = (decimal || "00").ljust(2, "0")[0, 2]
    formatted = "$#{whole_with_commas}.#{decimal}"
    self.negative? ? "(#{formatted})" : formatted
  end
end

class Integer
  # Converts an integer to a money string with dollar sign,
  # commas, and two decimal places. Negative numbers are
  # enclosed in parentheses.
  def to_money
    whole = self.abs.to_s
    whole_with_commas = whole.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    formatted = "$#{whole_with_commas}.00"
    self.negative? ? "(#{formatted})" : formatted
  end
end

class String
  # Converts a string to a money string with dollar sign,
  # commas, and two decimal places. Negative numbers are
  # enclosed in parentheses.
  def to_money
    Float(self).to_money
  end
end
