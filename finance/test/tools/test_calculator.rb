require_relative "../test_helper"

class TestCalculator < Minitest::Test
  def setup
    @calc = Finn::Tools::Calculator.new
  end

  def result_value(expr)
    JSON.parse(@calc.execute(expression: expr))["result"]
  end

  def test_basic_addition
    assert_in_delta 5.0, result_value("2 + 3")
  end

  def test_basic_subtraction
    assert_in_delta 1.0, result_value("5 - 4")
  end

  def test_float_division_not_integer
    assert_in_delta 3.14285, result_value("22 / 7"), 0.0001
  end

  def test_exponentiation_caret
    assert_in_delta 8.0, result_value("2^3")
  end

  def test_compound_interest
    # 1500 * 1.07^10
    expected = 1500 * (1.07**10)
    assert_in_delta expected, result_value("1500 * 1.07^10"), 0.01
  end

  def test_sqrt_function
    assert_in_delta 12.0, result_value("sqrt(144)")
  end

  def test_log10_function
    assert_in_delta 3.0, result_value("log10(1000)")
  end

  def test_pi_constant
    assert_in_delta Math::PI, result_value("pi")
  end

  def test_parentheses_grouping
    assert_in_delta 14.0, result_value("2 + 3 * 4")
    assert_in_delta 20.0, result_value("(2 + 3) * 4")
  end

  def test_disallows_arbitrary_code
    result = @calc.execute(expression: "system('echo pwned')")
    assert_match(/Error|Invalid/, result)
  end

  def test_disallows_string_literals
    result = @calc.execute(expression: '"hello"')
    assert_match(/Error|Invalid/, result)
  end

  def test_zero_division
    result = @calc.execute(expression: "1 / 0")
    assert_match(/Error/, result)
  end

  def test_returns_json_with_expression_and_result
    parsed = JSON.parse(@calc.execute(expression: "6 * 7"))
    assert_equal "6 * 7",   parsed["expression"]
    assert_in_delta 42.0,   parsed["result"]
    assert_equal  "42",     parsed["formatted"]
  end
end
