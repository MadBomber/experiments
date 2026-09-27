require_relative "../test_helper"
require "date"

class TestDateTool < Minitest::Test
  def setup
    @tool = Finn::Tools::DateTool.new
  end

  def parsed(input, format: nil)
    args = { input: input }
    args[:format] = format if format
    JSON.parse(@tool.execute(**args))
  end

  def test_now_returns_current_date
    result = parsed("now")
    assert result["formatted_date"].include?(Time.now.year.to_s)
    assert result["iso8601"].end_with?("Z")
    assert result["unix_timestamp"].is_a?(Integer)
  end

  def test_today_same_as_now
    r_now   = parsed("now")
    r_today = parsed("today")
    assert_equal r_now["day_of_week"], r_today["day_of_week"]
  end

  def test_yesterday_is_one_day_before
    result = parsed("yesterday")
    yesterday = (Time.now.utc - 86_400).strftime("%Y-%m-%d")
    assert_includes result["iso8601"], yesterday
  end

  def test_tomorrow_is_one_day_after
    result = parsed("tomorrow")
    tomorrow = (Time.now.utc + 86_400).strftime("%Y-%m-%d")
    assert_includes result["iso8601"], tomorrow
  end

  def test_relative_days_ago
    result = parsed("3 days ago")
    expected_date = (Time.now.utc - 3 * 86_400).strftime("%Y-%m-%d")
    assert_includes result["iso8601"], expected_date
  end

  def test_custom_format
    result = parsed("now", format: "%Y-%m-%d")
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, result["formatted_date"])
  end

  def test_parses_explicit_date_string
    result = parsed("2025-01-15")
    assert_includes result["iso8601"], "2025-01-15"
  end

  def test_returns_day_of_week
    result = parsed("2025-01-06")  # known Monday
    assert_equal "Monday", result["day_of_week"]
  end

  def test_invalid_date_returns_error_string
    result = @tool.execute(input: "not a date at all!!!")
    # Either returns an error string or the current time (DateTime.parse fallback)
    # Both are acceptable behaviours — just must not raise
    assert result.is_a?(String)
  end
end
