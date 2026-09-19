# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../examples/pure_ruby_indicators'

class PureRubyIndicatorsTest < Minitest::Test
  def test_sma_aligns_with_input_and_pads_warmup_with_nil
    values = PureRubyIndicators.sma([1.0, 2.0, 3.0, 4.0, 5.0], period: 3)

    assert_equal 5, values.size
    assert_nil values[0]
    assert_nil values[1]
    assert_in_delta 2.0, values[2], 1e-9
    assert_in_delta 4.0, values[4], 1e-9
  end

  def test_ema_seeds_with_sma_then_smooths
    values = PureRubyIndicators.ema([1.0, 2.0, 3.0, 4.0], period: 3)

    assert_nil values[0]
    assert_in_delta 2.0, values[2], 1e-9 # seed = SMA(1,2,3)
    assert_in_delta 3.0, values[3], 1e-9 # (4-2)*0.5 + 2
  end

  def test_rsi_is_100_on_pure_uptrend_and_0_on_pure_downtrend
    up = PureRubyIndicators.rsi(Array.new(20) { |i| 10.0 + i }, period: 14)
    down = PureRubyIndicators.rsi(Array.new(20) { |i| 30.0 - i }, period: 14)

    assert_nil up[13]
    assert_in_delta 100.0, up[14], 1e-9
    assert_in_delta 0.0, down[14], 1e-9
  end

  def test_rsi_is_50_when_gains_equal_losses
    prices = (0..20).map { |i| i.even? ? 10.0 : 11.0 }
    values = PureRubyIndicators.rsi(prices, period: 14)
    assert_in_delta 50.0, values.last, 1.0
  end

  def test_rsi_too_short_input_returns_all_nils
    assert PureRubyIndicators.rsi([1.0, 2.0], period: 14).all?(&:nil?)
  end

  def test_rsi_value_handles_zero_loss
    assert_equal 100.0, PureRubyIndicators.rsi_value(1.0, 0.0)
    assert_in_delta 50.0, PureRubyIndicators.rsi_value(1.0, 1.0), 1e-9
  end
end
