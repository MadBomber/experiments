module Util
  
  def self.compare_2_arrays_of_floats(a, b)
    a.length == b.length && delete_nans_and_truncate_floats_to_strings(a) == delete_nans_and_truncate_floats_to_strings(b)
  end

  def self.truncate_float_to_string(f)
    "%.10f" % f
  end

  def self.delete_nans_and_truncate_floats_to_strings(a)
    a.delete_if{ |e| e.nan? }.map{ |e| truncate_float_to_string(e) }
  end

  def self.ohlc(opens, highs, lows, closes)
    o = []
    opens.each_with_index do |e, i|
      o << [opens[i], highs[i], lows[i], closes[i]]
    end
    o
  end
  
end