require_relative "../test_helper"

# Unit tests for the YahooFinance helper methods that do NOT require
# a live network connection. Live API tests are in test/integration/.
class TestYahooFinanceModule < Minitest::Test
  # Stand-alone class that includes only the helpers we want to test
  class TestHost
    include Finn::Tools::YahooFinance
  end

  def setup
    @host = TestHost.new
  end

  # --- raw_value ---

  def test_raw_value_returns_plain_scalar
    assert_equal 180.5, @host.raw_value({ "price" => 180.5 }, "price")
  end

  def test_raw_value_unwraps_hash_with_raw_key
    assert_equal 180.5, @host.raw_value({ "price" => { "raw" => 180.5, "fmt" => "$180.50" } }, "price")
  end

  def test_raw_value_falls_back_to_fmt
    assert_equal "$180.50", @host.raw_value({ "price" => { "fmt" => "$180.50" } }, "price")
  end

  def test_raw_value_returns_nil_for_missing_key
    assert_nil @host.raw_value({}, "price")
  end

  def test_raw_value_returns_nil_for_non_hash_obj
    assert_nil @host.raw_value(nil, "price")
  end

  # --- format_large_number ---

  def test_format_trillions
    assert_equal "3.00T", @host.format_large_number(3_000_000_000_000)
  end

  def test_format_billions
    assert_equal "1.50B", @host.format_large_number(1_500_000_000)
  end

  def test_format_millions
    assert_equal "2.75M", @host.format_large_number(2_750_000)
  end

  def test_format_thousands
    assert_equal "1.23K", @host.format_large_number(1_230)
  end

  def test_format_small_number
    assert_equal "42.5",  @host.format_large_number(42.5)
  end

  def test_format_nil_returns_na
    assert_equal "N/A", @host.format_large_number(nil)
  end

  def test_format_negative_billion
    assert_equal "-2.00B", @host.format_large_number(-2_000_000_000)
  end

  # --- epoch_to_date ---

  def test_epoch_to_date_converts_unix_timestamp
    ts = Time.utc(2024, 1, 15).to_i
    assert_equal "2024-01-15", @host.epoch_to_date(ts)
  end

  def test_epoch_to_date_nil_returns_na
    assert_equal "N/A", @host.epoch_to_date(nil)
  end

  def test_epoch_to_date_zero_returns_na
    assert_equal "N/A", @host.epoch_to_date(0)
  end
end
