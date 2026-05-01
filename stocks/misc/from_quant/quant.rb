require "quant/version"

module Quant

  def self.sma(values, n)
    acc = 0
    values.inject_with_index([]) do |m, e, i|
      acc += e
      if i < (n - 1)
        m << not_a_number
      elsif i == (n - 1)
        m << acc / n
      else
        acc = acc - values[i - n]
        m << acc / n
      end
    end
  end

  def self.donchian_channel(ohlc, n)
    dc = []
    ohlc.each_with_index do |e, i|
      if i < (n - 1)
        dc << [not_a_number, not_a_number]
      else
        c = ohlc[(i - n + 1)..(i)].flatten
        dc << [c.max, c.min]
      end
    end
    dc
  end

  def self.tr(ohlc)
    tr = []
    ohlc.each_with_index do |e, i|
      tr << if i == 0
        not_a_number
      else
        high       = e[1]
        low        = e[2]
        last_close = ohlc[i - 1][3]
        [ high - low, (high - last_close).abs, (last_close - low).abs ].max
      end
    end
    tr
  end

  def self.atr(ohlc, n)
    tr = tr(ohlc)
    tr.delete_if{ |e| e.nan? }
    a = sma(tr, n)
    0.upto(ohlc.length - tr.length - 1) { a.unshift(not_a_number) } if ohlc.length > tr.length
    a
  end

  private

  def self.not_a_number
    0 / 0.0
  end

end
