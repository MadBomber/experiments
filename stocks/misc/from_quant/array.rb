class Array

  def highs
    inject([]) { |a, e| a << e[0] }
  end

  def lows
    inject([]) { |a, e| a << e[1] }
  end

end